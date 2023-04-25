-------------------------------------
-- Basic helper functions -----------
-------------------------------------
local function graphDeco(color, headline, overlay)
  local deco = View.GraphDecoration.create()
  deco:setGraphColor(color[1], color[2], color[3], color[4] or 255)
  deco:setTitle(headline or '')
  deco:setGraphType('LINE')
  deco:setDynamicSizing(true)
  deco:setAspectRatio('EQUAL')
  deco:setYBounds(-5, 20)
  deco:setXBounds(0, 80)
  if overlay then
    deco:setAxisVisible(false)
    deco:setBackgroundVisible(false)
    deco:setGridVisible(false)
    deco:setLabelsVisible(false)
    deco:setTicksVisible(false)
  end
  return deco
end

local helper = {}
helper.graphDeco = graphDeco
return helper