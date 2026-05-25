# [fnchooft.github.io](https://fnchooft.github.io)

This repo was created with the aid of Claude Design.
A new tool which helps you design websites, powerpoints etc.

## Testing locally

```bash
erl -s inets -eval 'inets:start(httpd, [{server_name, "my_server"}, {document_root, "."}, {server_root, "."}, {port, 8000}, {mime_types, [{"html", "text/html"}, {"js", "text/javascript"}, {"css", "text/css"}]}])'
```
