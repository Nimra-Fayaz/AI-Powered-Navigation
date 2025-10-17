#!/usr/bin/env python3
import sys
import urllib.request
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse
import json

class LinkExtractor(HTMLParser):
    def __init__(self, base_url):
        super().__init__()
        self.links = []
        self.base_url = base_url
        self.text_content = []
        self.current_tag = None

    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        if tag == 'a':
            for attr, value in attrs:
                if attr == 'href':
                    absolute_url = urljoin(self.base_url, value)
                    # Only include links from the same domain
                    if urlparse(absolute_url).netloc == urlparse(self.base_url).netloc:
                        self.links.append(absolute_url)

    def handle_endtag(self, tag):
        self.current_tag = None

    def handle_data(self, data):
        # Skip script and style content
        if self.current_tag not in ['script', 'style']:
            text = data.strip()
            if text:
                self.text_content.append(text)

def fetch_and_parse(url):
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            html = response.read().decode('utf-8')

        parser = LinkExtractor(url)
        parser.feed(html)

        # Remove duplicates while preserving order
        unique_links = list(dict.fromkeys(parser.links))

        result = {
            'url': url,
            'text': ' '.join(parser.text_content),
            'links': unique_links
        }

        print(json.dumps(result))
        return 0

    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        return 1

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fetch_page.py <url>", file=sys.stderr)
        sys.exit(1)

    sys.exit(fetch_and_parse(sys.argv[1]))
