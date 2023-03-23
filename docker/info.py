import sys
from pathlib import Path

file = Path(sys.argv[1])
file.write_text(
    file.read_text().replace(
        "    return demo",
        """
    with demo:
        gr.Markdown(
          'Created by [neggles/sd-webui-docker](https://github.com/neggles/sd-webui-docker)'
        )
    return demo
""",
        1,
    )
)
