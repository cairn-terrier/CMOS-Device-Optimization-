# Sentaurus TCAD project handoff to Codex

This handoff contains the source assignment, original uploaded process code, latest corrected scripts, and a summary of the technical conversation. It is a portable project package, not an automatic migration of the chat or a verbatim chat export. Prepared 17 October 2026.

## Start prompt

Read START_HERE.md, CONVERSATION_CONTEXT.md, current_code/README.md, and the assignment PDF in originals/. Continue this Sentaurus TCAD assignment from the current state. First audit the revised process/device/extraction scripts against the assignment and the original code. The immediate goal is a 2 um NMOS with a thermally GROWN 30 nm gate oxide using O2, tempOx and timeOx, followed by the assignment-defined linear VT0 extraction. Do not substitute oxide deposition or assume 1000 C/30 min gives 30 nm. Establish a practical oxidation calibration and validate the code with the available Sentaurus environment. If the simulator or original project dependencies are unavailable, state precisely what is missing and prepare the next runnable steps. Explain changes clearly, with physical intuition and explicit units. Do not claim a simulated result without executing the simulation.

## Files

- originals/DesignExercisePDP-2026.pdf: complete assignment; especially pp. 1–2 and 5.
- originals/Code_original.txt: original user-uploaded SProcess deck, preserved without edits.
- current_code/sprocess_fps.cmd: latest revised SProcess deck, using thermal O2 oxidation.
- current_code/sdevice_des.cmd: added linear Id-Vg device simulation.
- current_code/inspect_ins.cmd: added maximum-gm tangent extraction.
- current_code/README.md: detailed run instructions, defaults, changes and assumptions.
- CONVERSATION_CONTEXT.md: request history, decisions, theory discussed, limitations and next steps.
- process_changes.diff: original-to-current process diff.

## Current status

Code preparation is complete but simulation is NOT validated. No Sentaurus process/device simulation has run in this workspace, no 30 nm thermal recipe has been calibrated, and no numerical VT0 has been obtained. The layout CMOS130_lyt.mac, full original Workbench project, and original course SDevice settings were not provided. The added SDevice deck is an explicit modeling assumption and must be reconciled with the actual course template.

The immediate next task is review and oxide calibration, NOT 1 um optimization.
