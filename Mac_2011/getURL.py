#!/bin/python
"""
Filename        : getURL.py
Copyright (C)   : Nathan L. Toner
Created         : 2013-06-11
Modified        : 2013-06-13
Modified By     : Nathan L. Toner

Description     : Access a web page using the POST method and return the result.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
"""

# Import the required libraries
from urllib import urlencode
from urllib2 import Request, urlopen, URLError, ProxyHandler, build_opener, install_opener
import argparse

# Set up our argument parser
parser = argparse.ArgumentParser(description='Sends LaTeX string to web server and returns meta data used by LaTeX in Word project')
parser.add_argument('webAddr', type=str, help='Web address of LaTeX in Word server')
parser.add_argument('--formula', metavar='FRML', type=str, help='A LaTeX formula string')
parser.add_argument('--fontsize', metavar='SIZE', type=int, default=10, help='Integer representing font size (can be 10, 11, or 12. Default 10)')
parser.add_argument('--proxServ', metavar='SERV', type=str, help='Web address of proxy server, i.e. http://proxy.server.com:80')
parser.add_argument('--proxType', metavar='TYPE', type=str, default='http', help='Type of proxy server, i.e. http')

# Get the arguments from the parser
args = parser.parse_args()

# Define formula string if input
if args.formula:
    values = {'formula': str(args.fontsize) + '.' + args.formula}   # generate formula from args
else:
    values = {}

# Define proxy settings if proxy server is input.
if args.proxServ:       # set up the proxy server support
    proxySupport = ProxyHandler({args.proxType: args.proxServ})
    opener = build_opener(proxySupport)
    install_opener(opener)

# Set up the data object
data = urlencode(values)
data = data.encode('utf-8')

# Send request to the server and receive response, with error handling!
try:
    req = Request(args.webAddr, data)

    # Read the response and print to a file
    response = urlopen(req)
    print response.read()

except URLError, e:
    if hasattr(e, 'reason'):    # URL error case
        # a tuple containing error code and text error message
        print 'Error: Failed to reach a server.'
        print 'Reason: ', e.reason
    elif hasattr(e, 'code'):    # HTTP error case
        # HTTP error code, see section 10 of RFC 2616 for details
        print 'Error: The server could not fulfill the request.'
        print 'Error code: ', e.code
        # print e.read()

