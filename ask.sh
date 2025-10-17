#!/bin/bash

# Check arguments
if [ $# -ne 2 ]; then
    echo "USAGE:"
    echo "  ./ask.sh <website> \"<question>\""
    echo ""
    echo "DESCRIPTION:"
    echo "  ask.sh is a command-line tool that answers a specific question based on"
    echo "  the content of a website."
    echo ""
    echo "PARAMETERS:"
    echo "  <website>"
    echo "    The url of the Website to analyze. This parameter is required."
    echo ""
    echo "  \"<question>\""
    echo "    The question to ask about the content of the website. This parameter is required and"
    echo "    must be enclosed in quotes."
    exit 1
fi

WEBSITE="$1"
QUESTION="$2"
MAX_ITERATIONS=10
VISITED_URLS=()

# Function to check if URL has been visited
is_visited() {
    local url="$1"
    for visited in "${VISITED_URLS[@]}"; do
        if [ "$visited" = "$url" ]; then
            return 0
        fi
    done
    return 1
}

# Function to call Ollama API
query_ollama() {
    local prompt="$1"
    local response=$(curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"llama3.1\",
        \"prompt\": \"$prompt\",
        \"stream\": false
    }" 2>/dev/null)

    echo "$response" | jq -r '.response'
}

# Function to fetch page content
fetch_page() {
    local url="$1"
    python3 fetch_page.py "$url"
}

# Main navigation loop
current_url="$WEBSITE"
iteration=0
answer_found=false

echo "Starting navigation from: $current_url"
echo "Question: $QUESTION"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ] && [ "$answer_found" = false ]; do
    iteration=$((iteration + 1))

    # Check if already visited
    if is_visited "$current_url"; then
        echo "Already visited $current_url, stopping to avoid loop."
        break
    fi

    # Mark as visited
    VISITED_URLS+=("$current_url")

    echo "[$iteration] Fetching: $current_url"

    # Fetch page content
    page_data=$(fetch_page "$current_url")

    if [ $? -ne 0 ]; then
        echo "Error fetching page: $current_url"
        break
    fi

    # Extract text and links
    page_text=$(echo "$page_data" | jq -r '.text' | head -c 4000)
    links=$(echo "$page_data" | jq -r '.links[]' 2>/dev/null | head -20)

    # First prompt: Check if current page has the answer
    echo "[$iteration] Analyzing content..."
    check_prompt="You are analyzing a webpage to answer a question.

Question: $QUESTION

Page content (first 4000 chars):
$page_text

IMPORTANT: You must answer the question COMPLETELY and THOROUGHLY with ALL required details. If the page contains COMPLETE information including specific names, contacts, and all relevant details, respond with 'ANSWER: ' followed by the complete answer. If the page does NOT contain COMPLETE information (missing contacts, names, or other details), you MUST respond with 'NAVIGATE' only. Do NOT answer partially."

    check_prompt_escaped=$(echo "$check_prompt" | jq -Rs .)
    check_response=$(curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"llama3.1\",
        \"prompt\": $check_prompt_escaped,
        \"stream\": false,
        \"options\": {
            \"temperature\": 0.3
        }
    }" | jq -r '.response')

    # Check if answer is found
    if echo "$check_response" | grep -q "^ANSWER:"; then
        echo ""
        echo "=== ANSWER FOUND ==="
        echo "$check_response" | sed 's/^ANSWER: *//'
        echo ""
        answer_found=true
        exit 0
    fi

    # Second prompt: Decide which link to navigate to
    if [ -n "$links" ]; then
        echo "[$iteration] Deciding next navigation step..."

        # Create numbered list of links
        links_numbered=$(echo "$links" | nl -w1 -s'. ')

        nav_prompt="You are a web navigation agent. Your goal is to find information to answer this question: $QUESTION

You are currently at: $current_url

The current page has the following links (numbered):
$links_numbered

Based on the question and the available links, which ONE link should we navigate to next to find the answer?
Respond with ONLY the number of the most relevant link (just the number, like '3'). Choose the link most likely to contain the answer."

        nav_prompt_escaped=$(echo "$nav_prompt" | jq -Rs .)
        link_number=$(curl -s http://localhost:11434/api/generate -d "{
            \"model\": \"llama3.1\",
            \"prompt\": $nav_prompt_escaped,
            \"stream\": false,
            \"options\": {
                \"temperature\": 0.2,
                \"num_predict\": 5
            }
        }" | jq -r '.response' | grep -oE '[0-9]+' | head -1)

        if [ -n "$link_number" ] && [ "$link_number" -gt 0 ]; then
            next_url=$(echo "$links" | sed -n "${link_number}p")
            if [ -n "$next_url" ]; then
                echo "[$iteration] Next: $next_url"
                current_url="$next_url"
            else
                echo "[$iteration] Invalid link number. Using current page content for answer."
                # Try to extract answer from current page anyway
                final_prompt="Based on the following content, answer this question: $QUESTION

Content:
$page_text

Provide a comprehensive answer:"

                final_prompt_escaped=$(echo "$final_prompt" | jq -Rs .)
                final_answer=$(curl -s http://localhost:11434/api/generate -d "{
                    \"model\": \"llama3.1\",
                    \"prompt\": $final_prompt_escaped,
                    \"stream\": false
                }" | jq -r '.response')

                echo ""
                echo "=== ANSWER ==="
                echo "$final_answer"
                echo ""
                break
            fi
        else
            echo "[$iteration] No valid next link found. Using current page content for answer."
            # Try to extract answer from current page anyway
            final_prompt="Based on the following content, answer this question: $QUESTION

Content:
$page_text

Provide a comprehensive answer:"

            final_prompt_escaped=$(echo "$final_prompt" | jq -Rs .)
            final_answer=$(curl -s http://localhost:11434/api/generate -d "{
                \"model\": \"llama3.1\",
                \"prompt\": $final_prompt_escaped,
                \"stream\": false
            }" | jq -r '.response')

            echo ""
            echo "=== ANSWER ==="
            echo "$final_answer"
            echo ""
            break
        fi
    else
        echo "[$iteration] No links found on page. Using current content for answer."
        # Generate answer from current page
        final_prompt="Based on the following content, answer this question: $QUESTION

Content:
$page_text

Provide a comprehensive answer:"

        final_prompt_escaped=$(echo "$final_prompt" | jq -Rs .)
        final_answer=$(curl -s http://localhost:11434/api/generate -d "{
            \"model\": \"llama3.1\",
            \"prompt\": $final_prompt_escaped,
            \"stream\": false
        }" | jq -r '.response')

        echo ""
        echo "=== ANSWER ==="
        echo "$final_answer"
        echo ""
        break
    fi

    echo ""
done

if [ "$answer_found" = false ] && [ $iteration -ge $MAX_ITERATIONS ]; then
    echo "Maximum iterations reached. Generating answer from collected information..."
fi
