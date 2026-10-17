# EE4623 — Part 1: 2 µm NMOS baseline and VT0 extraction

This package edits the supplied SProcess code and adds SDevice and Inspect scripts. It does not contain a simulated Vth result. Sentaurus and the required CMOS130_lyt.mac layout were not available for execution here. The files need your existing CMOS_130nm-v0 Workbench project and its layout/mask definitions.

## 1. Use these defaults

| Quantity | Value | Where to set it |
|---|---|---|
| Device | NMOS only | Workbench `Domain=NMOS`; delete/disable PMOS experiments |
| Drawn gate length | 2.0 µm | Workbench `Lgate=2.0` |
| Substrate | Boron, p-type, 1.35e15 cm^-3 | SProcess `Nsub` |
| Nominal substrate resistivity | 10 ohm.cm | Represented by the assignment's corresponding doping; not a separate implant input |
| Gate oxide | 300 Å = 30 nm = 0.030 µm | SProcess `gox=0.030` |
| Vt-adjust species | Boron | Single SProcess implant |
| Vt-adjust dose | 2.0e12 cm^-2 | SProcess `Qvt` |
| Vt-adjust energy | 30 keV | SProcess `Evt` |
| Expected VT0 | Approximately 0.7–0.8 V | Comparison target only; never imposed in the deck |
| Drain bias for VT0 | 0.05 V | SDevice drain ramp |
| Source and body biases | 0 V | SDevice electrodes |
| Gate sweep | 0 to 5 V, 5 mV output spacing | SDevice gate ramp |
| Device temperature | 300 K | SDevice assumption |

The initial numerical/default values above come from page 2; the threshold definition and electrical biases come from page 5 of the supplied assignment. The gate sweep endpoint covers the assignment's 5 V operating range. Device temperature is an explicit modeling assumption.

## 2. Install and run in Workbench

1. Copy your existing CMOS_130nm-v0 project into a separate working project. Keep its layout file `CMOS130_lyt.mac` and other supporting files.
2. Keep one experiment with `Domain=NMOS`, `Lgate=2.0`. Keep existing process split settings (`Poly`, `Ext`, `SD`, `Silicide`, `Contact`, `DeviceMesh`). Do not create columns for the new local `fset` defaults yet.
3. Replace the SProcess master command text with `sprocess_fps.cmd` (identical to the delivered `Code.txt`). Keep the stretch expression `Lgate-0.060`: the 0.060 is the original layout reference length, not the requested device length.
4. Put an SDevice tool after the final process/mesh node and use `sdevice_des.cmd` in its command editor. If an SDevice tool already exists, first retain a copy of its settings for comparison; the original SDevice file was not supplied.
5. Put an Inspect tool directly after that SDevice tool and use `inspect_ins.cmd`. This is an Inspect script, not a native Sentaurus Visual script.
6. Preprocess the experiment. Check that the SDevice `Grid="@tdr@"` resolves to the FINAL MIRRORED process output `n<final-process-node>_fps.tdr`, not `_half_fps.tdr` or the intermediate gate-oxide snapshot. If your template resolves another output, set Grid to that actual final filename.
7. Run all required process nodes, then SDevice, then Inspect. Do not try to run the supplied `.cmd` files directly outside Workbench without replacing the `@...@` references.
8. Read `VT0` / `Vtgm` in the Workbench results or Inspect log. Inspect also writes `n<inspect-node>_VT0_results.txt`. These two labels represent the same threshold here.

SDevice prefixes the gate-sweep output with `IdVg_`; Inspect loads `IdVg_@plot@`. If your project uses a custom output naming rule, inspect the generated filename and update the Inspect `proj_load` line to that exact file. Use the gate-sweep output, not the separate drain-ramp output.

## 3. What changed in SProcess

- Substrate boron changed from 1.0e15 to 1.35e15 cm^-3.
- Gate oxide changed from 0.0015 to 0.030 µm.
- The seven original boron well/Vt implants were replaced by one boron implant, 2.0e12 cm^-2 at 30 keV. There is no additional deep p-well implant in this simplified starting recipe.
- All PMOS process branches/implants were removed.
- NMOS halo and LDD implant commands were commented out. Their separate extension activation anneal was also disabled. Mesh labels called HALO or EXT may remain; those labels do not implant dopants.
- The well anneal was simplified to the original 1050 °C peak hold for 20 s. The default deposited gate oxide uses one 740 °C, 20 min inert anneal in place of the original gate-anneal ramps. Removing ramps changes the total thermal budget; this is a simplified baseline recipe.
- The original n+ source/drain implant (arsenic, 5.5e15 cm^-2, 55 keV), 1000 °C / 1.5 s activation, spacers, STI, silicide, and most other process steps were retained. These are inherited choices, not green-highlighted assignment defaults.
- The original explicit n+ polysilicon doping (1.5e20 cm^-3) was retained.
- The final device keeps the full 10 µm substrate rather than truncating it at 0.5 µm. A coarse bulk refinement was added. For the low substrate doping, a shallow body boundary should not be assumed harmless to depletion electrostatics.
- Dielectric regions are retained at final remeshing; the blanket final `strip Oxide` is disabled. Oxide-interface refinement and the gate-contact search box were adjusted for the thicker oxide.
- The symmetry coordinate uses `(Ymax+Ymin)/2`. Reflection failures now stop processing.
- A gate-oxide snapshot and a final center-channel active/total doping profile are saved.

## 4. Important distinction: fixed oxide baseline versus thermal oxidation

The default is `UseThermalOxidation=0`. It deposits a nominal 30 nm oxide directly and applies an inert anneal. This gives a controlled thickness for the FIRST electrical baseline, but it is NOT a calibrated thermal-oxidation process and does not model silicon consumption or oxidation-enhanced diffusion from growing that oxide.

For the assignment's recommended thermal-oxidation process and later oxidation-time DOE, set `UseThermalOxidation=1`. The code then uses one simple oxidation command:

```tcl
diffuse temperature= $GateOxTemp<C> time= $GateOxTime<min> O2
```

The included 1000 °C / 30 min values are ONLY starting guesses, not a claim that they grow 30 nm. Run to the saved gate-oxide snapshot, measure the oxide vertically at the channel center, and adjust GateOxTime until tox is approximately 0.030 µm. Keep `gox=0.030` as the target used by subsequent geometry operations. Then rerun every downstream process/device step and establish VT0 again. Use this thermally grown baseline for the final oxidation-time study. Do not mix deposited-oxide and thermally grown-oxide results as though only tox had changed.

The assignment does not supply enough information to infer one unique oxidation time from tox alone. A numerical growth time could not be calibrated without running Sentaurus.

## 5. Threshold definition

At VDS=0.05 V and VBS=0 V:

1. Plot drain current versus gate voltage on a LINEAR current scale.
2. Calculate gm=dID/dVGS.
3. Find the point where gm is maximum.
4. Extend the tangent at that point to ID=0.

The x-intercept is:

VT0 = VGS_at_gmMax - ID_at_gmMax / gmMax.

This matches the definition on assignment page 5. Do not subtract an additional VDS/2=0.025 V from this reported number. That correction is used in some alternative threshold conventions, but is not the raw tangent-intercept definition requested here.

Inspect also extracts ICRIT as the actual current on the original Id-Vg curve at VGS=VT0; it is not the tangent's zero current. ICRIT can later be used for the saturation-threshold extraction defined in the assignment.

## 6. Check the first run before accepting VT0

- Final cross-section: approximately 2 µm drawn gate, continuous oxide beneath the gate near 30 nm, n+ source/drain on either side, all four contacts, full mirrored structure, and p-type body.
- Distinguish drawn Lgate from metallurgical Leff after lateral source/drain diffusion.
- Inspect the saved center-channel profile; the substrate concentration and implanted channel concentration are different quantities.
- Verify that the final gate oxide is intact; measure the thickness rather than relying only on the deposition input.
- Use the low-drain-bias linear-current curve. Inspect the gm curve and tangent. A boundary maximum or numerical spike should not be accepted as a valid extraction. The script stops if the maximum occurs at a sweep endpoint.
- A value outside 0.7–0.8 V is diagnostic information, not a reason to change the specified default dose. Check geometry, active doping, thermal budget, gate treatment, interface charge, and model settings first.

## 7. SDevice assumptions and verification limits

The original SDevice command/parameter files and layout were not included in the upload. The added device deck is therefore an explicit conventional starting model, not a reconstruction of the course's original electrical setup. It uses Fermi statistics, doping/surface/high-field mobility, OldSlotboom bandgap narrowing, SRH recombination, and built-in material parameters at 300 K.

The gate remains an explicit doped polysilicon region; no extra metal-gate Barrier is applied. No fixed oxide/interface charge is added. If the original course SDevice deck specifies a different gate treatment, interface charge, material parameter file, or model, reconcile it before treating the result as the definitive course baseline. Do not tune those settings simply to make VT0 equal 0.75 V.

Checked locally: default values and unit conversions, active implant list, disabled halo/LDD operations, file consistency, bias/extraction logic, and archive integrity. Sentaurus preprocessing, meshing, solver convergence, and the extracted numerical VT0 remain unverified until run in your licensed environment.

Sources: supplied DesignExercisePDP-2026 (1).pdf, pp. 1–2 and 5; supplied Code.txt; Synopsys-authored Sentaurus training examples (public mirrors):
- https://ghzphy.github.io/Sentaurus_Training/sp/sp_2.html (thermal growth versus deposited oxide)
- https://ghzphy.github.io/Sentaurus_Training/sd/sd_1.html (device deck and bias sweeps)
- https://kolegite.com/EE_library/books_and_lectures/Автоматизация%20на%20Проектирането%20в%20Електрониката/Sentaurus_Training/insp/insp_4.html (maximum-gm tangent extraction)
