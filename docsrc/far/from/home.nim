import nimib, strutils
nbInit
nb.doc.context["path_to_root"] = %nb.doc.context{"path_to_root"}.getStr.replace("/", r"\") # for CI since I run locally on Windows and CI runs on Linux: behaviour is the same
nb.doc.context["path_to_here"] = %nb.doc.context{"path_to_here"}.getStr.replace("/", r"\") # for CI since I run locally on Windows and CI runs on Linux: behaviour is the same
nb.partials["document"] = """
<html>
<head></head>
<body>
  <a href=".">🕷️</a> is {{path_to_here}} <a href="{{path_to_root}}">🏡</a> ({{path_to_root}})
</body>
</html>
"""
nbSave