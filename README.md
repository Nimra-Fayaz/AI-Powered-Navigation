# AI-Powered Web Navigation Tool

A command-line application that uses LLM-based reasoning to intelligently navigate websites and answer questions. The tool combines web scraping with AI-driven navigation logic to autonomously explore website content, extract relevant information, and provide comprehensive answers based on user queries.

## Overview

This project implements an intelligent web navigation agent that can:
- Navigate websites autonomously based on natural language questions
- Extract and analyze web page content
- Make intelligent decisions about which links to follow
- Provide comprehensive answers by exploring multiple pages if needed

## Project Structure

- **[ask.sh](ask.sh)** - Main bash script that orchestrates the AI-powered web navigation
- **[fetch_page.py](fetch_page.py)** - Python utility for fetching and parsing web pages
- **[assgn.html](assgn.html)** - Assignment documentation with project requirements

## Components

### 1. ask.sh (Main Navigation Script)

The main bash script that implements the intelligent navigation loop. It:
- Takes a website URL and a question as input
- Uses Ollama's `llama3.1` model for AI reasoning
- Implements iterative navigation with loop detection
- Extracts answers from web content or navigates to relevant pages
- Limits navigation to 10 iterations to prevent infinite loops

**Features:**
- Tracks visited URLs to avoid circular navigation
- Uses two-stage AI prompting: answer detection and navigation decision
- Handles edge cases (no links, invalid responses, etc.)
- Outputs comprehensive answers with context

### 2. fetch_page.py (Web Scraper)

A Python script that handles web page fetching and parsing:
- Extracts text content from HTML pages
- Finds and normalizes all links on the page
- Filters links to keep only same-domain URLs
- Returns JSON output with URL, text content, and links
- Handles timeouts and errors gracefully

### 3. assgn.html (Assignment Documentation)

Contains the original project requirements and specifications for the course assignment.

## Prerequisites

- **Bash shell** (Unix/Linux/WSL2 on Windows)
- **Python 3** with standard library
- **curl** - for making HTTP requests
- **jq** - for JSON processing
- **Ollama** - for running the LLM locally
- **llama3.1 model** - pulled via Ollama

## Installation

1. Install Ollama following the [official documentation](https://github.com/ollama/ollama/tree/main/docs)

2. Pull the llama3.1 model:
   ```bash
   ollama pull llama3.1
   ```

3. Make the scripts executable:
   ```bash
   chmod +x ask.sh fetch_page.py
   ```

4. Ensure Ollama is running:
   ```bash
   ollama serve
   ```

## Usage

```bash
./ask.sh <website> "<question>"
```

### Parameters

- **website** - The URL of the website to analyze (required)
- **question** - The question to ask about the website content (required, must be in quotes)

### Example

```bash
./ask.sh https://www.mines-stetienne.fr/ "Name the research centers and departments of Mines Saint-Etienne, with their contact."
```

This will:
1. Start at the homepage
2. Navigate to relevant sections (e.g., /recherche/)
3. Find specific information about research centers
4. Extract contact information
5. Provide a comprehensive answer

## How It Works

1. **Initial Request**: The script receives a URL and question
2. **Page Fetching**: Uses `fetch_page.py` to download and parse the page
3. **Content Analysis**: Sends page content to Ollama to check if it contains the answer
4. **Navigation Decision**: If answer not found, AI selects the most relevant link to follow
5. **Iteration**: Repeats steps 2-4 until answer is found or max iterations reached
6. **Answer Extraction**: Provides final answer based on collected information

## Technical Details

- **Loop Prevention**: Tracks visited URLs to avoid infinite loops
- **Content Limiting**: Analyzes first 4000 characters of each page
- **Link Limiting**: Considers up to 20 links per page
- **Temperature Control**: Uses low temperature (0.2-0.3) for consistent navigation decisions
- **Error Handling**: Gracefully handles network errors, missing content, and invalid responses

## API Integration

The tool uses the [Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md) for LLM interactions:
- Endpoint: `http://localhost:11434/api/generate`
- Model: `llama3.1`
- Streaming: Disabled for easier parsing

## Limitations

- Maximum 10 navigation iterations
- Only follows links within the same domain
- Processes first 4000 characters of page content
- Requires local Ollama instance running
- Single-threaded navigation (one page at a time)

## Course Context

This project was developed as part of the TFSD course at Mines Saint-Étienne. It demonstrates:
- Unix shell scripting
- Python web scraping
- AI/LLM integration
- Command-line tool development
- JSON processing with jq

## License

Educational project for Mines Saint-Étienne coursework.
