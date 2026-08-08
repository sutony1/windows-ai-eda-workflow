# EasyEDA and JLCPCB handoff

## Import path

1. Save the KiCad `.kicad_pro`, `.kicad_sch`, and `.kicad_pcb` together.
2. Zip the KiCad project for EasyEDA import.
3. If EasyEDA reports `encoding-error`, use 嘉立创EDA格式转换助手 and import the generated `.epro`.
4. Compare component count, track count, top/bottom copper, outline and drill against KiCad.
5. Run EasyEDA schematic/PCB checks, but separate conversion-only Fab/text warnings from copper errors.

## Hard boundary

If the imported EasyEDA schematic has zero nets, floating pins, missing components, or a PCB/schematic netlist mismatch, it is a visual conversion only. Do not edit the schematic and synchronize it back into the PCB. Rebuild the schematic with real EasyEDA/JLC components before using EasyEDA as the source of truth.

For bare PCB production, prefer the checked KiCad Gerber ZIP. EasyEDA import is not required for JLCPCB quoting.

## Quote and first order

Upload the Gerber ZIP to JLCPCB's PCB online order page. For the included example, the baseline is 2 layers, about 70 x 45 mm, 1.6 mm FR-4, 1 oz copper, green solder mask, white silkscreen and HASL.

For a first prototype:

- Select five boards.
- Request and manually confirm the production artwork.
- Inspect top/bottom copper, drill, outline and silkscreen.
- Select no SMT and no stencil unless BOM, CPL, LCSC part numbers, package orientation and through-hole processing have all been rebuilt and checked.

SMT processing estimates exclude component purchase costs unless the quote explicitly includes matched parts. Special ICs, connectors, trimmers and through-hole parts can add procurement, extended-part, changeover and manual insertion costs.

Never click final submit, pay, or production-confirm actions without explicit user authorization.
