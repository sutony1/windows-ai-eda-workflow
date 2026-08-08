# Reproducibility record

## Validated machine

| Layer | Version or revision |
|---|---|
| KiCad | 10.0.5 x64 |
| KiCAD-MCP-Server | 2.6.0, `0dc3ee8ccad6efbf62c02b6a8736ddcf43118188` |
| Node.js | 24.13.1 |
| Python | 3.12 |
| ngspice | 42+ KLU x64 |
| LTspice | 26.0.2.1 |
| EasyEDA Pro | 3.2.175 |
| easyeda-agent | 0.21.2 |

## Evidence expected on a new computer

- Environment check output.
- ngspice smoke-test output.
- LTspice sweep results with macro-model provenance.
- Successful read-only KiCad MCP response.
- ERC and DRC reports.
- Gerber ZIP plus visual inspection note.
- easyeda-agent daemon and connector health.
- Any version deviations and the regression test performed after each deviation.

## Known conversion limitation

The validated EasyEDA import preserved the visible PCB reasonably well but did not preserve the schematic as a reliable electrical source: metadata overlapped, some component/library mappings failed, and netlist validation was not trustworthy. The KiCad project and its Gerbers therefore remain authoritative.
