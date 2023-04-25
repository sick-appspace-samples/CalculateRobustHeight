
--Start of Global Scope---------------------------------------------------------

-------------------------------------------------------------------------------------
-- Helper functions -----------------------------------------------------------------
-------------------------------------------------------------------------------------

local helper = require('helpers')

-------------------------------------------------------------------------------------
-- Settings -------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local ENABLE_NOISE = true
local SMOOTH_PROFILE = false
local SMOOTHING_KERNEL_SIZE = 9

local DELAY = 2000 -- For demonstration purpose only

local POLYGON = { --in mm
  Point.create(0   ,    0),
  Point.create(15  ,    0),
  Point.create(15.5,   10),
  Point.create(25  , 10.5),
  Point.create(27  ,    5),
  Point.create(35  ,    5),
  Point.create(37  ,   18),
  Point.create(45  , 17.5),
  Point.create(47  ,   15),
  Point.create(57  ,   15),
  Point.create(60  ,   19),
  Point.create(63  ,   19),
  Point.create(70  ,    6),
  Point.create(72  ,    6),
  Point.create(75  ,    0),
  Point.create(80  ,    0),
}

local LINE_COLOR = {59, 156, 208}
local HIGHLIGHT_COLOR = {242, 148, 0}
local GREYED_OUT = {230, 230, 230}
local GREYED_OUT_DARK = {200, 200, 200}

-------------------------------------------------------------------------------------
-- Main functionality ---------------------------------------------------------------
-------------------------------------------------------------------------------------

local function main()
  -------------------------------------
  -- Scan polygon ---------------------
  -------------------------------------

  local polyProfile = Profile.createFromPoints(POLYGON)
  polyProfile = Profile.resizeScale(polyProfile, 50)

  -------------------------------------
  -- Generate random noise ------------
  -------------------------------------

  if ENABLE_NOISE then
    Profile.addNoiseInplace(polyProfile, "UNIFORM", -0.1, 0.1)
  end

  -------------------------------------
  -- Smooth profile -------------------
  -------------------------------------

  if SMOOTH_PROFILE then
    polyProfile = polyProfile:gauss(SMOOTHING_KERNEL_SIZE)
  end

  -------------------------------------
  -- Step detection -------------------
  -------------------------------------

  local firstDerivative = polyProfile:gaussDerivative(25, 'FIRST')
  firstDerivative = firstDerivative:multiplyConstant(10) -- Amplify derivative

  -- Binarize and invert: |value| < threshold -> 10 else 0
  local binarizedDerivative = firstDerivative:binarize(-0.25, 0.25, 10)

  -- find positive edges of binarized derivative
  local secondDerivativeOfBinarized = binarizedDerivative:gaussDerivative(25, 'SECOND')
  secondDerivativeOfBinarized = secondDerivativeOfBinarized:multiplyConstant(100)
  secondDerivativeOfBinarized = secondDerivativeOfBinarized:clamp(0, 10000) --remove all negative peaks

  local edgeIndices = secondDerivativeOfBinarized:findLocalExtrema('MAX', 5, 2)

  -- Add start and end of profile if it wasn't a slope
  if binarizedDerivative:getValue(0) > 0 then
    edgeIndices[#edgeIndices + 1] = 0
  end

  if binarizedDerivative:getValue(binarizedDerivative:getSize() - 1) > 0 then
    edgeIndices[#edgeIndices + 1] = binarizedDerivative:getSize() - 1
  end
  -- Sort indices
  table.sort(edgeIndices)

  -- Table for found platforms (raw values)
  local resultPlatformProfiles = {}
  -- Table for filtered found platforms
  local medianPlatformProfiles = {}

  for i = 2, #edgeIndices, 2 do
    -- Use found edges to crop platform
    resultPlatformProfiles[#resultPlatformProfiles + 1] = Profile.crop(polyProfile, edgeIndices[i - 1], edgeIndices[i])

    -- Calculate robust height of the platform using the median (other possibilities: max, min, mean)
    local height = resultPlatformProfiles[#resultPlatformProfiles]:getMedian()
    -- Get the coordinates of the first and last point
    local coordinates = polyProfile:getCoordinate({edgeIndices[i - 1], edgeIndices[i]})
    -- Create new profile with only two points
    medianPlatformProfiles[#medianPlatformProfiles + 1] = Profile.createFromVector({height, height}, coordinates)
  end

  --Print result to console
  print("\nNumber of resultPlatformProfiles found: " .. #resultPlatformProfiles.."\n")

  for i, medianStep in pairs(medianPlatformProfiles) do
    local height = Profile.getValue(medianStep, 0)
    local startX = Profile.getCoordinate(medianStep, 0)
    local endX = Profile.getCoordinate(medianStep, Profile.getSize(medianStep) - 1)

    print("Step nr. " .. i .. ": range = [" .. startX .. "mm, " .. endX .. "mm], height = "
      .. height .. "mm, length = " .. endX - startX .. "mm")
  end
  print('\nSee viewer on device page for visualization')

  -------------------------------------
  -- Visualization --------------------
  -------------------------------------

  local v = View.create()
  v:clear()

  v:addProfile(polyProfile, helper.graphDeco(LINE_COLOR, 'Scanned profile'))
  v:present()

  Script.sleep(DELAY) -- For demonstration purpose only

  v:clear()
  local id = v:addProfile(polyProfile, helper.graphDeco(GREYED_OUT, 'First derivative'))
  v:addProfile(firstDerivative, helper.graphDeco(LINE_COLOR, '', true), nil, id)
  v:present()

  Script.sleep(DELAY) -- For demonstration purpose only

  v:clear()
  id = v:addProfile(polyProfile, helper.graphDeco(GREYED_OUT, 'Binarized derivative'))
  v:addProfile(firstDerivative, helper.graphDeco(GREYED_OUT_DARK, '', true), nil, id)
  v:addProfile(binarizedDerivative, helper.graphDeco(LINE_COLOR, '', true), nil, id)
  v:present()

  Script.sleep(DELAY) -- For demonstration purpose only

  v:clear()
  id = v:addProfile(firstDerivative, helper.graphDeco(GREYED_OUT, 'Found steps'))
  v:addProfile(binarizedDerivative, helper.graphDeco(GREYED_OUT_DARK, '', true), nil, id)
  v:addProfile(polyProfile, helper.graphDeco(LINE_COLOR, '', true), nil, id)
  v:addProfile(resultPlatformProfiles, helper.graphDeco(HIGHLIGHT_COLOR, '', true), nil, id)
  v:present()

  Script.sleep(DELAY) -- For demonstration purpose only

  v:clear()

  id = v:addProfile(firstDerivative, helper.graphDeco(GREYED_OUT, 'Median filtered steps'))
  v:addProfile(binarizedDerivative, helper.graphDeco(GREYED_OUT_DARK, '', true), nil, id)
  v:addProfile(polyProfile, helper.graphDeco(LINE_COLOR, '', true), nil, id)
  v:addProfile(medianPlatformProfiles, helper.graphDeco(HIGHLIGHT_COLOR, '', true), nil, id)
  v:present()
end
Script.register('Engine.OnStarted', main)
-- serve API in global scope
