# Plan: Macro Breakdown with Liquid Glass Scroll Effect

## Phase 1: Data Preparation [checkpoint: 75a8a9f]

- [x] Task: Update `InteractiveMacroCard` to accept an array of `FoodItem` objects 75a8a9f
- [x] Task: Implement a computed property within the card to filter and sort items by their contribution to the specific macro 75a8a9f
- [x] Task: Conductor - User Manual Verification 'Data Preparation' (Protocol in workflow.md) 75a8a9f

## Phase 2: Breakdown UI and Scroll Effect

- [x] Task: Implement the `MacroBreakdownList` component inside the expanded state of `InteractiveMacroCard` 6443b70
- [x] Task: Apply `.scrollEdgeEffectStyle(.soft, for: .vertical)` to the breakdown ScrollView 6443b70
- [x] Task: Apply a `LinearGradient` mask to the ScrollView to achieve the "soft edge" melting effect 6443b70
- [x] Task: Style the individual list rows to match the "Liquid Glass" theme (subtle dividers, refined typography) 6443b70
- [~] Task: Conductor - User Manual Verification 'Breakdown UI and Scroll Effect' (Protocol in workflow.md)

## Phase 3: Integration and Polish

- [ ] Task: Update `TodayView` to pass the `items` query result to each `InteractiveMacroCard`
- [ ] Task: Refine expansion animations to account for the new list content
- [ ] Task: Verify end-to-end data flow and visual fidelity
- [ ] Task: Conductor - User Manual Verification 'Integration and Polish' (Protocol in workflow.md)
