@lab.Variable(GlobalReqHeader)

!INSTRUCTIONS[][requirement-scenario]

@lab.DropDownList(ShowHints)[Yes,No]

:::hint-toggle
<span class="label slider-heading">Hints Enabled</span>

<span class="label">No</span>
<label class="switch">
  <input type="checkbox" class="checkMode" checked>
  <span class="slider round"></span>
</label>
<span class="label">Yes</span>
:::

:::HiddenVariables(ShowVariables=Yes)
@lab.DropDownList(ShowToggle)[Yes,No]
@lab.DropDownList(ShowGuided)[Yes,No]
@lab.DropDownList(ShowAdvanced)[Yes,No]
@lab.DropDownList(ShowActivity)[Yes,No]
:::
