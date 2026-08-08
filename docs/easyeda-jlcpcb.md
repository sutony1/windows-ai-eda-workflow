# EasyEDA and JLCPCB handoff

## Preferred bare-board route

Export checked Gerbers from KiCad and upload the ZIP to the JLCPCB order page. This avoids depending on cross-EDA schematic conversion. On the validated example, the upload preview succeeded and the site quoted five 70 mm x 45 mm, two-layer FR-4 bare boards; prices and promotions are time-dependent and must be checked again.

## EasyEDA import route

When an editable EasyEDA copy is required:

1. Save the KiCad schematic and PCB together and ZIP them.
2. Use 嘉立创 EDA's KiCad import. If it reports `encoding-error`, use the vendor format conversion assistant and import the resulting project.
3. Import required symbol/footprint libraries to an owner library under the intended account or team.
4. Rebind components and 3D models where the converter cannot map them.
5. Verify component count, net count, two copper layers, track count, drill count, and board outline.

If the imported schematic reports zero nets, missing components, overlapped metadata, or netlist mismatch, treat it as a visual copy only. Do not synchronize it back into the authoritative KiCad project.

## Ordering choices

- Bare PCB only: choose no SMT service. The PCB fee does not include components or assembly.
- SMT assembly: processing/engineering/stencil/placement fees are separate from component charges. Parts are matched and priced later from the BOM.
- For a prototype, production-artwork confirmation is useful but optional and charged separately.
- Review board quantity, dimensions, layer count, thickness, copper weight, solder-mask color, surface finish, drill options, address, invoice, and shipping before submission.

This repository and its automation stop before final order submission and payment.
