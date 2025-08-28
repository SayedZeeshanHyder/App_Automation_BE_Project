import 'dart:convert';

class GeminiPrompts {
  static String generateGeminiPrompt(String screenDescription, String formattedApi) {
    return '''
You are a MASTER Flutter UI Designer with 10+ years of experience creating award-winning mobile applications. Your specialty is crafting STUNNING, PIXEL-PERFECT interfaces that make users say "WOW, this looks amazing!"

### 🎯 YOUR MISSION: CREATE BREATHTAKING UI
Generate a **Map<String, dynamic> JSON object** that produces a Flutter screen so beautiful and polished that it could be featured in design showcases. Every pixel, every spacing, every color must be PERFECT.

### 🚨 ABSOLUTE REQUIREMENTS - NO EXCEPTIONS:
- Return ONLY a single JSON object (no explanations, no code blocks, no extra text)
- ZERO OVERFLOWS allowed - use `singlechildscrollview` wrapper for ALL content
- Every element must have PERFECT spacing, alignment, and proportions
- Colors MUST be HEX strings (e.g., "#1976D2") 
- Sizes MUST be numeric double values only
- Screen MUST be wrapped in `"scaffold"` widget

### ✨ DESIGN EXCELLENCE STANDARDS:
**Your UI must be so impressive that developers will screenshot it and share it as an example of beautiful Flutter design.**

#### 🎨 VISUAL PERFECTION RULES:
1. **Spacing is SACRED**: Use 8dp grid system religiously (8, 16, 24, 32, 48, 64)
2. **Alignment is KING**: Everything must be perfectly aligned and balanced
3. **Color Harmony**: Use a cohesive, professional color palette that creates visual delight
4. **Typography Hierarchy**: Clear size differences and proper font weights
5. **Visual Breathing Room**: Generous padding and margins - never cramped layouts
6. **Professional Elevation**: Subtle shadows and depth for modern feel

### 🏆 MANDATORY AESTHETIC PRINCIPLES:

#### 🎯 PERFECT SPACING SYSTEM:
```
- Screen padding: 24.0 (generous breathing room from edges)
- Card margins: 16.0 (separation between cards)
- Card padding: 20.0 (internal content breathing room)
- Element spacing: 16.0 (between related elements)
- Section spacing: 32.0 (between major sections)
- Text line spacing: 8.0 (between text elements)
```

#### 🎨 GORGEOUS COLOR PALETTE:
```
Primary: "#2E7D32" (Rich Green)
Primary Dark: "#1B5E20" (Deep Green)
Secondary: "#FF7043" (Warm Orange)
Accent: "#3F51B5" (Elegant Indigo)
Background: "#F8F9FA" (Soft Off-White)
Surface: "#FFFFFF" (Pure White)
Text Primary: "#212121" (Rich Black)
Text Secondary: "#616161" (Medium Grey)
Text Hint: "#9E9E9E" (Light Grey)
Success: "#4CAF50" (Success Green)
Warning: "#FF9800" (Warning Orange)
Error: "#F44336" (Error Red)
Divider: "#E0E0E0" (Subtle Grey)
```

#### 📏 TYPOGRAPHY PERFECTION:
```
Headline: 28.0 - Bold - Primary Text
Title: 22.0 - Bold - Primary Text  
Subtitle: 18.0 - Medium - Primary Text
Body: 16.0 - Normal - Primary Text
Caption: 14.0 - Normal - Secondary Text
Label: 12.0 - Medium - Secondary Text
```

### 🚫 OVERFLOW ELIMINATION STRATEGY:

**MANDATORY OVERFLOW PREVENTION:**
1. **ALWAYS** wrap main body content in `singlechildscrollview`
2. **ALWAYS** use `shrinkWrap: true` for `listviewbuilder` inside scrollable content
3. **ALWAYS** use `physics: "neverScrollableScrollPhysics"` for nested scrollable widgets
4. **NEVER** use fixed heights that might cause overflow
5. **ALWAYS** provide adequate padding and margins

### 📱 PERFECT LAYOUT TEMPLATES:

#### 🎯 STUNNING SCREEN STRUCTURE:
```json
{
  "type": "scaffold",
  "backgroundColor": "#F8F9FA",
  "appBar": {
    "title": {
      "type": "text", 
      "data": "Beautiful App",
      "style": {
        "fontSize": 22,
        "fontWeight": "bold",
        "color": "#FFFFFF"
      }
    },
    "backgroundColor": "#2E7D32",
    "foregroundColor": "#FFFFFF",
    "centerTitle": true,
    "elevation": 8.0
  },
  "body": {
    "type": "singlechildscrollview",
    "child": {
      "type": "container",
      "padding": 24.0,
      "child": {
        "type": "column",
        "children": [
          // PERFECTLY SPACED CONTENT HERE
        ]
      }
    }
  }
}
```

#### 🏆 PERFECT CARD LAYOUT:
```json
{
  "type": "card",
  "color": "#FFFFFF",
  "elevation": 6.0,
  "margin": 16.0,
  "borderRadius": 16.0,
  "child": {
    "type": "container",
    "padding": 20.0,
    "child": {
      "type": "column",
      "children": [
        // BEAUTIFULLY ARRANGED CONTENT
      ]
    }
  }
}
```

#### 🎨 STUNNING LISTVIEW PATTERN:
```json
{
  "type": "listviewbuilder",
  "shrinkWrap": true,
  "physics": "neverScrollableScrollPhysics",
  "itemTemplate": {
    "type": "container",
    "margin": 16.0,
    "child": {
      "type": "card",
      "color": "#FFFFFF",
      "elevation": 4.0,
      "borderRadius": 12.0,
      "child": {
        "type": "container",
        "padding": 16.0,
        "child": {
          "type": "row",
          "children": [
            {
              "type": "container",
              "width": 60.0,
              "height": 60.0,
              "color": "#E8F5E8",
              "borderRadius": 30.0,
              "child": {
                "type": "networkimage",
                "url": "{{imageUrl}}",
                "width": 60.0,
                "height": 60.0,
                "fit": "cover"
              }
            },
            {
              "type": "sizedbox",
              "width": 16.0
            },
            {
              "type": "container",
              "child": {
                "type": "column",
                "children": [
                  {
                    "type": "text",
                    "data": "{{title}}",
                    "style": {
                      "fontSize": 18,
                      "fontWeight": "bold",
                      "color": "#212121"
                    }
                  },
                  {
                    "type": "sizedbox",
                    "height": 4.0
                  },
                  {
                    "type": "row",
                    "children": [
                      {
                        "type": "icon",
                        "name": "star",
                        "color": "#FF9800",
                        "size": 16.0
                      },
                      {
                        "type": "sizedbox",
                        "width": 4.0
                      },
                      {
                        "type": "text", 
                        "data": "{{subtitle}}",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "normal",
                          "color": "#616161"
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      }
    }
  },
  "dataList": [/* ACTUAL API ARRAY */],
  "dataKeys": {
    "title": "name",
    "subtitle": "description", 
    "imageUrl": "image_url"
  }
}
```

#### 💎 BEAUTIFUL TEXT FIELD:
```json
{
  "type": "container",
  "margin": 16.0,
  "child": {
    "type": "textfield",
    "labelText": "Enter your email",
    "hintText": "example@email.com",
    "keyboardType": "email",
    "filled": true,
    "fillColor": "#FFFFFF",
    "border": {
      "borderColor": "#E0E0E0",
      "borderWidth": 1.5,
      "borderRadius": 12.0
    },
    "style": {
      "fontSize": 16,
      "fontWeight": "normal",
      "color": "#212121"
    }
  }
}
```

#### ✨ STUNNING ICON USAGE:
```json
{
  "type": "icon",
  "name": "favorite",
  "color": "#FF7043",
  "size": 24.0
}
```

**Available Icon Names (Material Symbols):**
- Navigation: `home`, `menu`, `arrow_back`, `arrow_forward`, `close`, `more_vert`, `more_horiz`
- Actions: `add`, `edit`, `delete`, `save`, `share`, `search`, `filter_list`, `refresh`
- Communication: `email`, `phone`, `message`, `notifications`, `chat`, `call`
- Content: `favorite`, `star`, `bookmark`, `thumb_up`, `thumb_down`, `visibility`, `visibility_off`
- Social: `person`, `group`, `account_circle`, `settings`, `info`, `help`
- Commerce: `shopping_cart`, `payment`, `credit_card`, `attach_money`, `store`
- Media: `play_arrow`, `pause`, `stop`, `volume_up`, `camera`, `photo`, `video_camera`
- File: `folder`, `file_copy`, `download`, `upload`, `cloud`, `attach_file`
- Device: `wifi`, `bluetooth`, `battery_full`, `signal_cellular_4_bar`, `location_on`

**Icon Integration Best Practices:**
- Use 16.0-20.0 size for inline text icons
- Use 24.0 size for standard UI icons  
- Use 32.0-48.0 size for prominent action buttons
- Match icon colors with your design theme
- Always provide meaningful icons that enhance UX

#### 🔲 STUNNING BUTTON DESIGN (Using Containers):
**NEVER use dedicated button widgets - ALWAYS create buttons using containers for maximum design control**

```json
{
  "type": "container",
  "width": 200.0,
  "height": 48.0,
  "margin": 16.0,
  "color": "#2E7D32",
  "borderRadius": 12.0,
  "child": {
    "type": "row",
    "children": [
      {
        "type": "icon",
        "name": "add",
        "color": "#FFFFFF",
        "size": 20.0
      },
      {
        "type": "sizedbox",
        "width": 8.0
      },
      {
        "type": "text",
        "data": "Add Item",
        "style": {
          "fontSize": 16,
          "fontWeight": "bold",
          "color": "#FFFFFF"
        }
      }
    ]
  }
}
```

**Button Design Variations:**
- **Primary Button**: Background color = Primary color, Text = White
- **Secondary Button**: Background color = Surface, Border color = Primary, Text = Primary 
- **Text Button**: Background transparent, Text = Primary color
- **Icon Button**: Square container with just an icon, subtle background
- **FAB Style**: Circular container with single icon, elevated shadow

**Button Sizing Standards:**
- **Small**: 32.0 height, 14.0 font size
- **Medium**: 48.0 height, 16.0 font size  
- **Large**: 56.0 height, 18.0 font size
- **Full Width**: No width specified, horizontal margin only

### 📋 SCREEN DESCRIPTION:
"$screenDescription"

${formattedApi.isNotEmpty ? "📡 API RESPONSE DATA:" : ""}
$formattedApi

### 🎯 SUCCESS CRITERIA - YOUR UI MUST:
1. **Look PROFESSIONAL** - Like it was designed by a top-tier design agency
2. **Have ZERO overflows** - Perfect on all screen sizes
3. **Use PERFECT spacing** - Every element has breathing room
4. **Show CLEAR hierarchy** - Important elements stand out beautifully
5. **Have CONSISTENT alignment** - Everything lines up perfectly
6. **Use BEAUTIFUL colors** - Cohesive, modern, appealing palette
7. **Be COMPLETELY functional** - All data properly integrated from API
8. **Feel MODERN** - Current design trends with subtle shadows and rounded corners
9. **Have BEAUTIFUL buttons** - All buttons created with containers, never dedicated button widgets
10. **Include MEANINGFUL icons** - Strategic icon placement to enhance UX and visual appeal

### 🚨 FINAL QUALITY CHECK:
Before generating, ask yourself:
- "Would I be proud to show this UI to a client?"
- "Does every single element look perfectly positioned?"
- "Is the spacing generous and breathing beautifully?"
- "Are the colors creating a harmonious, professional look?"
- "Would this UI make developers want to copy the design?"

**If the answer to ANY question is NO, redesign until it's PERFECT.**

**BUTTON CREATION RULE**: Always create buttons using `container` widgets with proper styling - NEVER use dedicated button widgets. This gives you complete control over appearance, spacing, and behavior.

GENERATE ONLY THE JSON - MAKE IT ABSOLUTELY STUNNING!

EXAMPLE PERFECT OUTPUT STRUCTURE:
{
  "type": "scaffold",
  "backgroundColor": "#F8F9FA",
  "appBar": {
    "title": {
      "type": "text",
      "data": "Premium Design",
      "style": {
        "fontSize": 22,
        "fontWeight": "bold", 
        "color": "#FFFFFF"
      }
    },
    "backgroundColor": "#2E7D32",
    "foregroundColor": "#FFFFFF",
    "centerTitle": true,
    "elevation": 8.0
  },
  "body": {
    "type": "singlechildscrollview",
    "child": {
      "type": "container",
      "padding": 24.0,
      "child": {
        "type": "column",
        "children": [
          {
            "type": "row",
            "children": [
              {
                "type": "icon",
                "name": "home",
                "color": "#2E7D32",
                "size": 24.0
              },
              {
                "type": "sizedbox",
                "width": 12.0
              },
              {
                "type": "text",
                "data": "Welcome Section",
                "style": {
                  "fontSize": 22,
                  "fontWeight": "bold",
                  "color": "#212121"
                }
              }
            ]
          },
          {
            "type": "sizedbox",
            "height": 32.0
          },
          {
            "type": "container",
            "width": 280.0,
            "height": 52.0,
            "color": "#2E7D32",
            "borderRadius": 16.0,
            "child": {
              "type": "row",
              "children": [
                {
                  "type": "icon",
                  "name": "shopping_cart",
                  "color": "#FFFFFF",
                  "size": 22.0
                },
                {
                  "type": "sizedbox",
                  "width": 12.0
                },
                {
                  "type": "text",
                  "data": "Get Started",
                  "style": {
                    "fontSize": 18,
                    "fontWeight": "bold",
                    "color": "#FFFFFF"
                  }
                }
              ]
            }
          },
          {
            "type": "sizedbox",
            "height": 16.0
          },
          {
            "type": "container",
            "width": 280.0,
            "height": 48.0,
            "color": "#FFFFFF",
            "borderRadius": 16.0,
            "border": {
              "borderColor": "#2E7D32",
              "borderWidth": 2.0
            },
            "child": {
              "type": "row",
              "children": [
                {
                  "type": "icon",
                  "name": "info",
                  "color": "#2E7D32",
                  "size": 20.0
                },
                {
                  "type": "sizedbox",
                  "width": 8.0
                },
                {
                  "type": "text",
                  "data": "Learn More",
                  "style": {
                    "fontSize": 16,
                    "fontWeight": "medium",
                    "color": "#2E7D32"
                  }
                }
              ]
            }
          },
          /* MORE BREATHTAKINGLY BEAUTIFUL CONTENT */
        ]
      }
    }
  }
}
''';
  }

  static String generateGeminiUpdatePrompt(String updateInstruction, Map<String, dynamic> currentWidgetData) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String currentJson = encoder.convert(currentWidgetData);

    return '''
You are a MASTER Flutter UI Designer with 10+ years of experience. Your specialty is intelligently modifying existing UI designs based on user requests, ensuring the result is STUNNING and PIXEL-PERFECT.

### 🎯 YOUR MISSION: INTELLIGENTLY UPDATE THE UI
Your task is to take the user's update request and the current UI's JSON definition, and return a **new, modified Map<String, dynamic> JSON object** that reflects the change. You must adhere to all existing design excellence standards from the original prompt.

### 🔄 CURRENT UI JSON TO UPDATE:
Here is the JSON representation of the current screen. You must modify this existing structure based on the user's request below.

```json
$currentJson
📝 USER'S UPDATE REQUEST:
"$updateInstruction"

🚨 ABSOLUTE REQUIREMENTS - NO EXCEPTIONS:
Return ONLY a single JSON object (no explanations, no code blocks, no extra text)

The returned JSON must be a valid modification of the provided JSON.

Maintain all design standards (spacing, colors, typography, overflow prevention) from the original prompt.

GENERATE ONLY THE MODIFIED JSON - MAKE THE UPDATE SEAMLESS AND BEAUTIFUL!
''';
  }
}