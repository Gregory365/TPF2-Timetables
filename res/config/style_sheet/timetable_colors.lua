require "tableutil"
local ssu = require "stylesheetutil"

-- extract colors with common api, default ingame console seems to output always the default colors!?
-- for _, c in ipairs(game.config.gui.lineColors) do; print("{" .. c[1] .. ", "  .. c[2] .. ", "  .. c[3] .. "}"); end;

local defaultColors = {
    { 0.96, 0.19, 0.21 },
    { 1, 0.93, 0.13 },
    { 0.4, 0.87, 0.25 },
    { 0.27, 0.69, 1 },
    { 0.79, 0.3, 0.81 },
    { 0.92, 0.46, 0.15 },
    { 0.54, 0.31, 0.15 },
    { 0, 0.43, 0.12 },
    { 0.16, 0.31, 0.57 },
    { 0.37, 0.17, 0.53 },
    { 0.83, 0.39, 0.44 },
    { 0.84, 0.64, 0.3 },
    { 0.71, 0.83, 0.4 },
    { 0.4, 0.82, 0.65 },
    { 0.62, 0.54, 0.82 },
    { 0.49, 0.16, 0.29 },
    { 0.34, 0.32, 0.24 },
    { 0.47, 0.52, 0.21 },
    { 0.07, 0.56, 0.6 },
    { 0.40, 0.25, 0.83 },
}

-- https://steamcommunity.com/sharedfiles/filedetails/?id=2033800555
local marc345 = {
    {0.50196078431373, 0, 0},
    {0.50196078431373, 0.16470588235294, 0},
    {0.50196078431373, 0.37647058823529, 0},
    {0.29411764705882, 0.50196078431373, 0},
    {0, 0.50196078431373, 0.16862745098039},
    {0.003921568627451, 0.45882352941176, 0.50196078431373},
    {0, 0.22352941176471, 0.50196078431373},
    {0.2078431372549, 0, 0.50196078431373},
    {0.45882352941176, 0, 0.50196078431373},
    {0.50196078431373, 0, 0.16862745098039},
    {0.70196078431373, 0, 0},
    {0.70196078431373, 0.23137254901961, 0},
    {0.70196078431373, 0.52549019607843, 0},
    {0.4078431372549, 0.70196078431373, 0},
    {0, 0.70196078431373, 0.23529411764706},
    {0.007843137254902, 0.64313725490196, 0.70196078431373},
    {0, 0.31372549019608, 0.70196078431373},
    {0.29411764705882, 0, 0.70196078431373},
    {0.64313725490196, 0, 0.70196078431373},
    {0.70196078431373, 0, 0.23529411764706},
    {1, 0, 0},
    {1, 0.33333333333333, 0},
    {1, 0.74901960784314, 0},
    {0.5843137254902, 1, 0},
    {0, 1, 0.33333333333333},
    {0, 1, 1},
    {0, 0.45098039215686, 1},
    {0.4156862745098, 0, 1},
    {0.91764705882353, 0, 1},
    {1, 0, 0.33333333333333},
    {0.98039215686275, 0.24705882352941, 0.24705882352941},
    {1, 0.50196078431373, 0.25098039215686},
    {1, 0.81176470588235, 0.25098039215686},
    {0.69019607843137, 1, 0.25098039215686},
    {0.25098039215686, 1, 0.50196078431373},
    {0.25098039215686, 0.93725490196078, 1},
    {0.25098039215686, 0.58823529411765, 1},
    {0.56078431372549, 0.25098039215686, 1},
    {0.93725490196078, 0.25098039215686, 1},
    {1, 0.25098039215686, 0.50196078431373},
    {0.96078431372549, 0.48235294117647, 0.48235294117647},
    {1, 0.66666666666667, 0.50196078431373},
    {1, 0.87450980392157, 0.50196078431373},
    {0.7921568627451, 1, 0.50196078431373},
    {0.50196078431373, 1, 0.66666666666667},
    {0.50196078431373, 0.95686274509804, 1},
    {0.50196078431373, 0.72549019607843, 1},
    {0.70980392156863, 0.50196078431373, 1},
    {0.95686274509804, 0.50196078431373, 1},
    {1, 0.50196078431373, 0.66666666666667},
    {1, 0.54117647058824, 0.4},
    {1, 0.70196078431373, 0.4},
    {1, 0.94901960784314, 0.4},
    {0.6, 1, 0.4},
    {0.4, 1, 0.74901960784314},
    {0.50196078431373, 0.83137254901961, 1},
    {0.4, 0.4, 1},
    {0.8, 0.4, 1},
    {1, 0.50196078431373, 0.83529411764706},
    {1, 1, 1},
    {1, 0.42352941176471, 0.25098039215686},
    {1, 0.62352941176471, 0.25098039215686},
    {1, 0.93333333333333, 0.2},
    {0.50196078431373, 1, 0.25098039215686},
    {0.25098039215686, 1, 0.68627450980392},
    {0.25098039215686, 0.74901960784314, 1},
    {0.25098039215686, 0.25098039215686, 1},
    {0.74901960784314, 0.25098039215686, 1},
    {1, 0.25098039215686, 0.74901960784314},
    {0.74901960784314, 0.74901960784314, 0.74901960784314},
    {1, 0.23529411764706, 0},
    {1, 0.50196078431373, 0},
    {1, 0.91764705882353, 0},
    {0.33333333333333, 1, 0},
    {0, 1, 0.5843137254902},
    {0, 0.66666666666667, 1},
    {0, 0, 1},
    {0.66666666666667, 0, 1},
    {1, 0, 0.66666666666667},
    {0.50196078431373, 0.50196078431373, 0.50196078431373},
    {0.6, 0.14117647058824, 0},
    {0.6, 0.30196078431373, 0},
    {0.6, 0.54901960784314, 0},
    {0.2, 0.6, 0},
    {0, 0.6, 0.34901960784314},
    {0, 0.49803921568627, 0.74901960784314},
    {0, 0, 0.6},
    {0.4, 0, 0.6},
    {0.6, 0, 0.40392156862745},
    {0.25098039215686, 0.25098039215686, 0.25098039215686},
    {0.34901960784314, 0.082352941176471, 0},
    {0.34901960784314, 0.17647058823529, 0},
    {0.34901960784314, 0.32156862745098, 0},
    {0.11764705882353, 0.34901960784314, 0},
    {0, 0.34901960784314, 0.20392156862745},
    {0, 0.33333333333333, 0.50196078431373},
    {0, 0, 0.34901960784314},
    {0.23529411764706, 0, 0.34901960784314},
    {0.34901960784314, 0, 0.23529411764706},
    {0, 0, 0}
}

-- https://steamcommunity.com/sharedfiles/filedetails/?id=2047925018
local mediziner = {
    {1, 1, 0},
    {1, 0.75294117647059, 0},
    {1, 0.56470588235294, 0},
    {1, 0, 0},
    {0.75294117647059, 0, 0.25098039215686},
    {0.50196078431373, 0, 0.50196078431373},
    {0.33333333333333, 0.18823529411765, 0.55294117647059},
    {0.16470588235294, 0.37647058823529, 0.6},
    {0.082352941176471, 0.51764705882353, 0.4},
    {0, 0.66274509803922, 0.2},
    {0.50196078431373, 0.83137254901961, 0.10196078431373},
    {1, 1, 0.74901960784314},
    {1, 0.94117647058824, 0.74901960784314},
    {1, 0.88627450980392, 0.74901960784314},
    {1, 0.74901960784314, 0.74901960784314},
    {0.94117647058824, 0.74901960784314, 0.8156862745098},
    {0.87843137254902, 0.74901960784314, 0.87843137254902},
    {0.83529411764706, 0.8, 0.89019607843137},
    {0.7921568627451, 0.84705882352941, 0.90196078431373},
    {0.77254901960784, 0.88235294117647, 0.85098039215686},
    {0.74901960784314, 0.91764705882353, 0.80392156862745},
    {0.87843137254902, 0.95686274509804, 0.77647058823529},
    {1, 1, 0.54117647058824},
    {1, 0.88627450980392, 0.54117647058824},
    {1, 0.7921568627451, 0.54117647058824},
    {1, 0.54117647058824, 0.54117647058824},
    {0.88627450980392, 0.54117647058824, 0.65882352941176},
    {0.77254901960784, 0.54117647058824, 0.77254901960784},
    {0.69411764705882, 0.62745098039216, 0.79607843137255},
    {0.6156862745098, 0.71372549019608, 0.81960784313725},
    {0.58039215686275, 0.78039215686275, 0.72549019607843},
    {0.54117647058824, 0.84705882352941, 0.63137254901961},
    {0.77647058823529, 0.92156862745098, 0.58823529411765},
    {1, 1, 0.31764705882353},
    {1, 0.83137254901961, 0.31764705882353},
    {1, 0.69019607843137, 0.31764705882353},
    {1, 0.31764705882353, 0.31764705882353},
    {0.83137254901961, 0.31764705882353, 0.49411764705882},
    {0.66274509803922, 0.31764705882353, 0.66274509803922},
    {0.54509803921569, 0.44705882352941, 0.69803921568627},
    {0.43137254901961, 0.57647058823529, 0.72941176470588},
    {0.37647058823529, 0.67450980392157, 0.5921568627451},
    {0.31764705882353, 0.77254901960784, 0.45490196078431},
    {0.66666666666667, 0.88627450980392, 0.38823529411765},
    {1, 1, 0.10980392156863},
    {1, 0.77647058823529, 0.10980392156863},
    {1, 0.5921568627451, 0.10980392156863},
    {1, 0.10980392156863, 0.10980392156863},
    {0.77647058823529, 0.10980392156863, 0.33725490196078},
    {0.55686274509804, 0.10980392156863, 0.55686274509804},
    {0.40392156862745, 0.27843137254902, 0.60392156862745},
    {0.25490196078431, 0.44313725490196, 0.64705882352941},
    {0.1843137254902, 0.57254901960784, 0.46274509803922},
    {0.10980392156863, 0.70196078431373, 0.28627450980392},
    {0.56078431372549, 0.85098039215686, 0.2},
    {0.89019607843137, 0.89019607843137, 0},
    {0.89019607843137, 0.66666666666667, 0},
    {0.89019607843137, 0.47843137254902, 0},
    {0.89019607843137, 0, 0},
    {0.66666666666667, 0, 0.22745098039216},
    {0.44313725490196, 0, 0.44313725490196},
    {0.29411764705882, 0.16862745098039, 0.49019607843137},
    {0.14509803921569, 0.33333333333333, 0.53725490196078},
    {0.074509803921569, 0.45882352941176, 0.35294117647059},
    {0, 0.5921568627451, 0.17647058823529},
    {0.44705882352941, 0.74117647058824, 0.090196078431373},
    {0.68235294117647, 0.68235294117647, 0},
    {0.68235294117647, 0.50980392156863, 0},
    {0.68235294117647, 0.36862745098039, 0},
    {0.68235294117647, 0, 0},
    {0.50980392156863, 0, 0.17254901960784},
    {0.34117647058824, 0, 0.34117647058824},
    {0.22745098039216, 0.12941176470588, 0.37647058823529},
    {0.10980392156863, 0.25490196078431, 0.4078431372549},
    {0.054901960784314, 0.35294117647059, 0.27058823529412},
    {0, 0.45098039215686, 0.13725490196078},
    {0.34509803921569, 0.56862745098039, 0.066666666666667},
    {0.45882352941176, 0.45882352941176, 0},
    {0.45882352941176, 0.34509803921569, 0},
    {0.45882352941176, 0.24705882352941, 0},
    {0.45882352941176, 0, 0},
    {0.34509803921569, 0, 0.11764705882353},
    {0.22745098039216, 0, 0.22745098039216},
    {0.15294117647059, 0.086274509803922, 0.25490196078431},
    {0.074509803921569, 0.17254901960784, 0.27450980392157},
    {0.03921568627451, 0.23529411764706, 0.18039215686275},
    {0, 0.30588235294118, 0.090196078431373},
    {0.23137254901961, 0.38039215686275, 0.047058823529412},
    {0.24705882352941, 0.24705882352941, 0},
    {0.24705882352941, 0.18823529411765, 0},
    {0.24705882352941, 0.13333333333333, 0},
    {0.24705882352941, 0, 0},
    {0.18823529411765, 0, 0.062745098039216},
    {0.12549019607843, 0, 0.12549019607843},
    {0.082352941176471, 0.047058823529412, 0.13725490196078},
    {0.03921568627451, 0.094117647058824, 0.14901960784314},
    {0.019607843137255, 0.12941176470588, 0.098039215686275},
    {0, 0.16470588235294, 0.050980392156863},
    {0.12549019607843, 0.20392156862745, 0.023529411764706},
    {0, 0, 0},
    {0.14901960784314, 0.14901960784314, 0.14901960784314},
    {0.23529411764706, 0.23529411764706, 0.23529411764706},
    {0.32549019607843, 0.32549019607843, 0.32549019607843},
    {0.41176470588235, 0.41176470588235, 0.41176470588235},
    {0.50196078431373, 0.50196078431373, 0.50196078431373},
    {0.6078431372549, 0.6078431372549, 0.6078431372549},
    {0.71764705882353, 0.71764705882353, 0.71764705882353},
    {0.82352941176471, 0.82352941176471, 0.82352941176471},
    {0.92941176470588, 0.92941176470588, 0.92941176470588},
    {1, 1, 1},
}

local availableColorSchemes = {
    defaultColors, marc345, mediziner
}

-- copied from timetable_helper.lua, import is not possible
-- if you change it here, also change it there!
local function getColorString(r, g, b)
    local x = string.format("%03.0f", (r * 100))
    local y = string.format("%03.0f", (g * 100))
    local z = string.format("%03.0f", (b * 100))
    return x .. y .. z
end

function data()
    local result = { }
    local lookup = { }

    local a = ssu.makeAdder(result)          -- helper function

    for _, schema in ipairs(availableColorSchemes) do
        for _, color in ipairs(schema) do
            local colorString = getColorString(color[1], color[2], color[3])
            if not lookup[colorString] then
                -- It is possible that a color is part of two color mods, but we only need one style for it.
                lookup[colorString] = true

                local colorArray = {color[1], color[2], color[3], 1}

                a("timetable-stationcolour-" .. colorString, {
                    backgroundColor = colorArray,
                })
                a("timetable-linecolour-" .. colorString, {
                    color = colorArray,
                })
            end
        end
    end

    return result
end