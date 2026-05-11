import os

conftest_path = "tests/conftest.py"
with open(conftest_path, "r") as f:
    content = f.read()

if "from sqlalchemy.ext.compiler import compiles" not in content:
    lines = content.split('\n')
    import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith("import ") or line.startswith("from "):
            import_idx = i
            
    injection = """
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import UUID
@compiles(UUID, "sqlite")
def compile_uuid(type_, compiler, **kw):
    return "CHAR(32)"
"""
    lines.insert(import_idx + 1, injection)
    with open(conftest_path, "w") as f:
        f.write('\n'.join(lines))
        print("Patched conftest.py with SQLite UUID compiler fallback")
else:
    print("Already patched")
