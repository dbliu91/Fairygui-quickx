---@class OverflowType
local OverflowType = {}
OverflowType.VISIBLE = "visible"
OverflowType.HIDDEN = "hidden"
OverflowType.SCROLL = "scroll"

---@class PackageItemType
local PackageItemType = {}

PackageItemType.IMAGE = "image"
PackageItemType.MOVIECLIP = "movieclip"
PackageItemType.COMPONENT = "component"
PackageItemType.ATLAS = "atlas"
PackageItemType.SOUND = "sound"
PackageItemType.FONT = "font"
PackageItemType.MISC = "misc"

---@class ScrollType
local ScrollType = {}

ScrollType.HORIZONTAL = "horizontal"
ScrollType.VERTICAL = "vertical"
ScrollType.BOTH = "both"

---@class ScrollBarDisplayType
local ScrollBarDisplayType = {}
ScrollBarDisplayType.DEFAULT = "default"
ScrollBarDisplayType.VISIBLE = "visible"
ScrollBarDisplayType.AUTO = "auto"
ScrollBarDisplayType.HIDDEN = "hidden"

---@class ChildrenRenderOrder
local ChildrenRenderOrder = {}
ChildrenRenderOrder.ASCENT = "ascent"
ChildrenRenderOrder.DESCENT = "descent"
ChildrenRenderOrder.ARCH = "arch"

---@class ButtonMode
local ButtonMode = {}
ButtonMode.COMMON = "Common"
ButtonMode.CHECK = "Check"
ButtonMode.RADIO = "Radio"

---@class DisplayListItem
---@field public packageItem PackageItem
---@field public type string
---@field public desc TXMLElement
local DisplayListItem = {}

---@class TextVAlignment
local TextVAlignment = {}
TextVAlignment.TOP = 0
TextVAlignment.CENTER = 1
TextVAlignment.BOTTOM = 2

---@class TextHAlignment
local TextHAlignment = {}
TextHAlignment.LEFT = 0
TextHAlignment.CENTER = 1
TextHAlignment.RIGHT = 2

---@class TextAutoSize
local TextAutoSize = {
    NONE = "none";
    BOTH = "both";
    HEIGHT = "height";
    SHRINK = "shrink";
}

---@class RelationType
local RelationType = {
    Left_Left = 0;
    Left_Center = 1;
    Left_Right = 2;
    Center_Center = 3;
    Right_Left = 4;
    Right_Center = 5;
    Right_Right = 6;

    Top_Top = 7;
    Top_Middle = 8;
    Top_Bottom = 9;
    Middle_Middle = 10;
    Bottom_Top = 11;
    Bottom_Middle = 12;
    Bottom_Bottom = 13;

    Width = 14;
    Height = 15;

    LeftExt_Left = 16;
    LeftExt_Right = 17;
    RightExt_Left = 18;
    RightExt_Right = 19;
    TopExt_Top = 20;
    TopExt_Bottom = 21;
    BottomExt_Top = 22;
    BottomExt_Bottom = 23;

    Size = 24;
};

---@class TweenType
local TweenType = {

    CUSTOM_EASING = -1;

    Linear = 0;

    Sine_EaseIn = 1;
    Sine_EaseOut = 2;
    Sine_EaseInOut = 3;

    Quad_EaseIn = 4;
    Quad_EaseOut = 5;
    Quad_EaseInOut = 6;

    Cubic_EaseIn = 7;
    Cubic_EaseOut = 8;
    Cubic_EaseInOut = 9;

    Quart_EaseIn = 10;
    Quart_EaseOut = 11;
    Quart_EaseInOut = 12;

    Quint_EaseIn = 13;
    Quint_EaseOut = 14;
    Quint_EaseInOut = 15;

    Expo_EaseIn = 16;
    Expo_EaseOut = 17;
    Expo_EaseInOut = 18;

    Circ_EaseIn = 19;
    Circ_EaseOut = 20;
    Circ_EaseInOut = 21;

    Elastic_EaseIn = 22;
    Elastic_EaseOut = 23;
    Elastic_EaseInOut = 24;

    Back_EaseIn = 25;
    Back_EaseOut = 26;
    Back_EaseInOut = 27;

    Bounce_EaseIn = 28;
    Bounce_EaseOut = 29;
    Bounce_EaseInOut = 30;

    TWEEN_EASING_MAX = 10000;
}

---@class UIEventType
local UIEventType = {
    Enter = 0;
    Exit = 1;
    Changed = 2;
    Submit = 3;

    TouchBegin = 10;
    TouchMove = 11;
    TouchEnd = 12;
    Click = 13;
    RollOver = 14;
    RollOut = 15;
    MouseWheel = 16;
    RightClick = 17;
    MiddleClick = 18;

    PositionChange = 20;
    SizeChange = 21;

    KeyDown = 30;
    KeyUp = 31;

    Scroll = 40;
    ScrollEnd = 41;
    PullDownRelease = 42;
    PullUpRelease = 43;

    ClickItem = 50;
    ClickLink = 51;
    ClickMenu = 52;
    RightClickItem = 53;

    DragStart = 60;
    DragMove = 61;
    DragEnd = 62;
    Drop = 63;

    GearStop = 70;
}

---@class LabelType
local LabelType = {
    TTF = 0;
    BMFONT = 1;
    CHARMAP = 2;
    STRING_TEXTURE = 3;
}

---@class GroupLayoutType
local GroupLayoutType = {
    NONE = 0;
    HORIZONTAL = 1;
    VERTICAL = 2;
}

---@class FlipType
local FlipType = {
    NONE = "";
    BOTH = "both";
    HORIZONTAL = "hz";
    VERTICAL = "vt";
}

---@class ActionTag
local ActionTag = {
    GEAR_XY_ACTION = 0xCC2100;
    GEAR_SIZE_ACTION = 0xCC2100 + 1;
    GEAR_LOOK_ACTION = 0xCC2100 + 2;
    GEAR_COLOR_ACTION = 0xCC2100 + 3;
    PROGRESS_ACTION = 0xCC2100 + 4;
    TRANSITION_ACTION = 0xCC2100 + 5; --remind:keep TRANSITION_ACTION as the last item
}

---@class LoaderFillType
local LoaderFillType = {
    NONE = "none";
    SCALE = "scale";
    SCALE_MATCH_HEIGHT = "scaleMatchHeight";
    SCALE_MATCH_WIDTH = "scaleMatchWidth";
    SCALE_FREE = "scaleFree";
    SCALE_NO_BORDER = "scaleNoBorder";
}

---@class ProgressTitleType
local ProgressTitleType = {
    PERCENT = "percent";
    VALUE_MAX = "valueAndmax";
    VALUE = "value";
    MAX = "max";
}

---@class TransitionActionType
local TransitionActionType = {
    XY = "XY";
    Size = "Size";
    Scale = "Scale";
    Pivot = "Pivot";
    Alpha = "Alpha";
    Rotation = "Rotation";
    Color = "Color";
    Animation = "Animation";
    Visible = "Visible";
    Sound = "Sound";
    Transition = "Transition";
    Shake = "Shake";
    ColorFilter = "ColorFilter";
    Skew = "Skew";
}

---@class PopupDirection
local PopupDirection = {
    AUTO = "auto";
    UP = "up";
    DOWN = "down";
}

---@class ListLayoutType
local ListLayoutType = {
    SINGLE_COLUMN = "column";
    SINGLE_ROW = "row";
    FLOW_HORIZONTAL = "flow_hz";
    FLOW_VERTICAL = "flow_vt";
    PAGINATION = "pagination";
}

---@class ListSelectionMode
local ListSelectionMode = {
    SINGLE = "single";
    MULTIPLE = "multiple";
    MULTIPLE_SINGLECLICK = "multipleSingleClick";
    NONE = "none";
}

-----------------------------------------------------------------------------

---@class FieldTypes
---@field OverflowType OverflowType
---@field PackageItemType PackageItemType
---@field ScrollType ScrollType
---@field ScrollBarDisplayType ScrollBarDisplayType
---@field ChildrenRenderOrder ChildrenRenderOrder
---@field ButtonMode ButtonMode
---@field TextVAlignment TextVAlignment
---@field TextHAlignment TextHAlignment
---@field TextAutoSize TextAutoSize
---@field RelationType RelationType
---@field TweenType TweenType
---@field UIEventType UIEventType
---@field LabelType LabelType
---@field GroupLayoutType GroupLayoutType
---@field FlipType FlipType
---@field ActionTag ActionTag
---@field LoaderFillType LoaderFillType
---@field ProgressTitleType ProgressTitleType
---@field PopupDirection PopupDirection
---@field ListLayoutType ListLayoutType
---@field ListSelectionMode ListSelectionMode
local FieldTypes = {}
FieldTypes.OverflowType = OverflowType
FieldTypes.PackageItemType = PackageItemType
FieldTypes.ScrollType = ScrollType
FieldTypes.ScrollBarDisplayType = ScrollBarDisplayType
FieldTypes.ChildrenRenderOrder = ChildrenRenderOrder
FieldTypes.ButtonMode = ButtonMode
FieldTypes.TextVAlignment = TextVAlignment
FieldTypes.TextHAlignment = TextHAlignment
FieldTypes.TextAutoSize = TextAutoSize
FieldTypes.RelationType = RelationType
FieldTypes.TweenType = TweenType
FieldTypes.UIEventType = UIEventType
FieldTypes.LabelType = LabelType
FieldTypes.GroupLayoutType = GroupLayoutType
FieldTypes.FlipType = FlipType
FieldTypes.ActionTag = ActionTag
FieldTypes.LoaderFillType = LoaderFillType
FieldTypes.ProgressTitleType = ProgressTitleType
FieldTypes.TransitionActionType = TransitionActionType
FieldTypes.PopupDirection = PopupDirection
FieldTypes.ListLayoutType = ListLayoutType
FieldTypes.ListSelectionMode = ListSelectionMode

return FieldTypes