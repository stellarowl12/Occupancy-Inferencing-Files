import webbrowser

b = webbrowser.get('safari')

fyle = open("Xively_dl_links.txt")

for url in fyle:
    b.open(url)

fyle.close()
