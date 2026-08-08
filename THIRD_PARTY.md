# Third-party components

This repository integrates, but does not redistribute, the following projects:

- KiCad: use the official installer and libraries from `kicad.org`.
- mixelpixx/KiCAD-MCP-Server: MIT-licensed upstream project. Validated baseline: `0dc3ee8ccad6efbf62c02b6a8736ddcf43118188`.
- ngspice: use official downloads and license terms.
- LTspice and LTC1967 models: Analog Devices terms apply. Obtain the LTC1967 model separately; it is intentionally not committed here.
- 嘉立创 EDA 专业版 and its conversion assistant: vendor software and terms apply.
- `tools/easyeda-conversion-forensics` contains only our interoperability scripts; it does not redistribute the conversion assistant, its worker, or its bundled 7-Zip binary.
- zhoushoujianwork/easyeda-agent: install CLI, connector and Skill from one matching upstream release.
- FreeRouting, PyVISA and VISA backends: optional components governed by their own licenses.

The included circuit example, scripts and generated manufacturing files are provided under this repository's MIT license, without any guarantee of fitness for mains-connected or safety-critical use.
