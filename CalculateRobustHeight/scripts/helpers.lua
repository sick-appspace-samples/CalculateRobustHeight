-------------------------------------
-- Basic helper functions -----------
-------------------------------------

local function getDeco(rgba, lineWidth, pointSize)
  lineWidth = lineWidth or 1
  pointSize = pointSize or 1
  rgba = rgba or {0, 0, 0}

  if #rgba == 3 then
    rgba[4] = 255
  end

  local deco = View.ShapeDecoration.create()
  deco:setLineColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setFillColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setLineWidth(lineWidth)
  deco:setPointSize(pointSize)
  return deco
end

local function getTextDeco(rgba, size, xPos, yPos)
  size = size or 1
  xPos = xPos or 0
  yPos = yPos or 0
  rgba = rgba or {0, 0, 0}

  if #rgba == 3 then
    rgba[4] = 255
  end

  local deco = View.TextDecoration.create()
  deco:setSize(size)
  deco:setColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setPosition(xPos, yPos)
  return deco
end

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

local function interpolate(point1, point2, x)
  local distance = Point.getX(point2) - Point.getX(point1)
  local xPos = (x - Point.getX(point1)) / distance
  return Point.getY(point1) * (1 - xPos) + Point.getY(point2) * xPos
end

local function polygonToProfile(polygon)
  local valueVec = {}
  local coordinateVec = {}
  local curPointIndex = 1
  for mm = polygon[1]:getX(), polygon[#polygon]:getX(), 0.1 do
    while polygon[curPointIndex + 1]:getX() < mm do
      curPointIndex = curPointIndex + 1
    end

    valueVec[#valueVec + 1] = interpolate(polygon[curPointIndex], polygon[curPointIndex + 1], mm)
    coordinateVec[#coordinateVec + 1] = mm
  end

  return Profile.createFromVector(valueVec, coordinateVec)
end

local function addRandomNoiseToProfile(profile, maxAmplitude)
  local randProfile = Profile.create(Profile.getSize(profile))
  for i = 0, Profile.getSize(profile) - 1 do
    local randomNum = math.random()
    local randomSign = math.random(2)
    randomNum = (-1) ^ randomSign * randomNum * maxAmplitude
    Profile.setValue(randProfile, i, randomNum)
  end
  return Profile.add(profile, randProfile)
end

local helper = {}
helper.getDeco = getDeco
helper.getTextDeco = getTextDeco
helper.graphDeco = graphDeco
helper.interpolate = interpolate
helper.polygonToProfile = polygonToProfile
helper.addRandomNoiseToProfile = addRandomNoiseToProfile
return helper