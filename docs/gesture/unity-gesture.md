# 1.Unity 输入变得简单：触摸事件和鼠标交互指南”
于 2023-12-17 23:03:07 发布 
原文链接：https://blog.csdn.net/qq_37270421/article/details/135052036

<<“Unity 输入变得简单：触摸事件和鼠标交互指南”>>
## 1.1触摸事件
触摸输入是许多移动和基于触摸屏的游戏和应用程序的一个基本方面。无论您是在创建休闲手机游戏还是 VR 体验，了解如何在 Unity 中使用触摸输入都至关重要。在本综合指南中，我们将探讨什么是触摸输入、如何使用它以及如何确定触摸的位置以及对应的游戏对象。

### 1.1.1 了解触摸输入：
在 Unity 中，触摸输入是指用户的手指与移动设备、平板电脑或任何支持触摸的平台的屏幕之间的交互。
在Unity中，触摸输入是使用Input类捕获的，该类提供了检测触摸事件的方法。


### 1.1.2 触摸输入类型：
Unity 支持多种类型的触摸输入，包括：
单点触控输入：这涉及到单个触摸点的检测，通常用于点击或拖动等简单交互。
多点触控输入：这允许同时检测和跟踪多个触摸点，这对于复杂的手势和交互非常有用。
检测触摸输入：要检测触摸输入，您需要用 C# 编写脚本来处理触摸事件。这是如何检测触摸及其位置的基本示例。

```csharp
using UnityEngine;
public class TouchInputManager : MonoBehaviour
{
    void Update()
    {
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0); // Get the first touch
        
            Vector2 touchPosition = touch.position; // for 2d games
            // Now you can use 'touchPosition' to determine where the user touched the screen.
        
            Vector3 touchPosition = Camera.main.ScreenToWorldPoint(touch.position); // for 3d games
            // Now you can use touchPosition to interact with your game objects.
        }
    }
}
```

Input.touchCount 属性指示当前有多少个触摸处于活动状态。

touch.position 和 Camera.main.ScreenToWorldPoint(touch.position) 在 Unity 的触摸输入系统中具有不同的用途：
> 1. touch.position触摸位置：   
>   这是指用户手指触摸设备屏幕的屏幕位置。它是一个二维向量（Vector2），表示触摸输入相对于屏幕尺寸的坐标。该位置位于屏幕空间中，并且不考虑游戏世界或相机。
> 2. Camera.main.ScreenToWorldPoint(touch.position):   
>   这部分代码获取屏幕空间触摸位置 (touch.position) 并将其转换为世界空间。 Camera.main参考指向场景中的主相机，ScreenToWorldPoint是Unity提供的将屏幕空间坐标转换为世界空间的方法。生成的 touchPosition 是世界空间中的 Vector3，表示游戏世界中触摸输入的 3D 位置。
在大多数 2D 游戏中，您使用正交相机。正交相机已经提供了屏幕空间和世界空间之间的直接映射，其中世界空间中的 1 个单位对应于屏幕上的 1 个单位。这意味着对于许多简单的2D游戏，您可以直接使用屏幕坐标，而不需要使用ScreenToWorldPoint。

触摸属性：
每个 Touch 对象都提供多个属性，包括：
position：触摸发生的屏幕位置。
deltaPosition：相对于前一帧的位置变化。
Phase：触摸的阶段（开始、移动、静止、结束、取消）。
FingerId：触摸的唯一标识符。


### 1.1.3 Touch Phases 触摸阶段：
Unity 中的触摸输入分为几个阶段，包括开始、移动、静止、结束和取消。这些阶段可帮助您跟踪触摸事件的生命周期。
> -Began 开始：
>   当用户第一次触摸屏幕时发生“开始”阶段。它代表触摸事件的开始。在此阶段，您可以捕获触摸的初始位置，启动动作或动画，并确定触摸了哪个游戏对象。
> 
> -Moved 移动：
>   当用户在启动触摸后在屏幕上拖动手指时（“开始”阶段），就会发生“移动”阶段。在此阶段，您可以连续跟踪触摸移动的位置。您可以使用此阶段执行拖动对象或滚动等操作。
> 
> -Stationary 固定式：
>   “静止”阶段用于检测触摸何时保持在固定位置而不移动。此阶段通常用于检测长按或点击并按住操作。
> 
> -Ended 结束：
>   当用户将手指离开屏幕时，发生“结束”阶段，表示触摸事件结束。在此阶段，您可以执行最终操作，例如激活按钮、释放拖动的对象或结束交互。
 
```csharp
Vector2 direction;
bool directionChanged;
Vector2 startPosition;

void Update() 
{
   if (Input.touchCount > 0) 
   {
        Touch touch = Input.GetTouch(0);
        switch (touch.phase) {
            case TouchPhase.Began:
            startPosition = touch.position;
            // Handle the start of the touch (e.g., record initial position).
            break;

            case TouchPhase.Moved:
            direction = touch.position - startPosition;
            // Handle touch movement (e.g., drag an object, get dorection of drag).
            break;

            case TouchPhase.Stationary:
            // Handle a stationary touch (e.g., long-press actions).
            break;

            case TouchPhase.Ended:
            directionChanged = true;
            // Handle the end of the touch (e.g., release a dragged object).
            break;
         }
     }
}
```
在此代码中，触摸阶段用于确定在触摸事件的每个阶段采取的适当操作。需要注意的是，在多点触控场景中，您可能会同时进行多个触摸，并且每次触摸都有自己的阶段，从而使您能够管理游戏或应用程序中的复杂交互。

### 1.1.4 -检测触摸的游戏对象：
要确定哪个游戏对象被触摸，您可以使用 Unity 的物理系统和光线投射。将碰撞器附加到您的游戏对象以启用此功能。这是一个例子：
此代码片段从触摸位置投射光线并检查与游戏对象的碰撞。

```cs
 float rayLength = 15f;  //Length of the ray

 void Update()
{
    if (Input.touchCount > 0)
    {
        Touch touch = Input.GetTouch(0);
        if (touch.phase == TouchPhase.Began)
        {

           // 3d example

           Ray ray = Camera.main.ScreenPointToRay(touch.position);
           RaycastHit hit;


            if (Physics.Raycast(ray, out hit))
            {
                GameObject touchedObject = hit.collider.gameObject;
                // Perform actions based on the touched object
            }

            
            // 2d example

            //Get the first object hit by the ray in up direction
            RaycastHit2D hit = Physics2D.Raycast(transform.position, Vector2.up, rayLength); // starting position , direction and length of the ray

            //If the ray hits something
            if (hit.collider != null)
            { 
                Debug.Log(" ray hit : " + hit.collider.gameObject.name);
            }

            // draw the ray in scene for debug purpose
            Debug.DrawRay(transform.position, Vector2.up * rayLength, Color.yellow);


        }
    }
}
```
此代码片段从触摸位置投射光线并检查与游戏对象的碰撞。

### 1.1.5 Multi Touches 多点触控：

多点触摸是指触摸屏设备同时检测和处理多个触摸输入的能力。 Unity 的输入系统使处理多点触控输入相对容易。这是一个简单的示例，说明如何实现多点触控来控制角色在屏幕上的移动。

让我们创建简单的CharacterController：
* 1. 它支持 2D 游戏中的角色移动和射击。
* 2. 跟随第一根手指的位置进行角色移动。
* 3. 同时触摸两个手指时会发射射弹。
 
```cs
using UnityEngine;

public class CharacterController : MonoBehaviour
{
    public float moveSpeed = 5.0f;
 
    private bool isShooting = false;
    private Rigidbody2D rb;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    void Update()
    {
        // Handle character movement using the first finger.
        HandleCharacterMovement();

        // Check for multi-touch input.
        HandleMultiTouchInput();
    }

    void HandleCharacterMovement()
    {
        // Iterate through all active touches.
        for (int i = 0; i < Input.touchCount; i++)
        {
            Touch touch = Input.GetTouch(i);

            // Character follows finger positions while any finger is touching the screen.
            Vector3 touchPosition = Camera.main.ScreenToWorldPoint(touch.position);
            touchPosition.z = transform.position.z; // Keep the character's Z position.

            switch (touch.phase)
            {
                case TouchPhase.Began:
                    // Character starts following the touch.
                    rb.velocity = Vector2.zero;
                    break;

                case TouchPhase.Moved:
                case TouchPhase.Stationary:
                    // Character follows the touch.
                    rb.MovePosition(touchPosition);
                    break;

                case TouchPhase.Ended:
                case TouchPhase.Canceled:
                    // Stop character movement when the touch ends.
                    rb.velocity = Vector2.zero;
                    break;
            }
        }
    }

    void HandleMultiTouchInput()
    {
        if (Input.touchCount == 2)
        {
            // Two fingers are touching the screen simultaneously.
            if (!isShooting)
            {
                // Shoot a projectile.
                Shoot();
            }
        }
        else
        {
            // Reset the shooting state if no longer touching with two fingers.
            isShooting = false;
        }
    }

    void Shoot()
    {
        isShooting = true;

        //  shooting logic
         
    }
}
```
在上面的脚本中，如果您同时用 3 个或更多手指触摸，它仍然会表现得好像您只有两个手指触摸屏幕。该脚本旨在通过检查 Input.touchCount == 2 来检测多点触摸输入。因此，无论您用多少根手指触摸屏幕，只要检测到两根手指，角色就会响应多点触摸。

## 1.2.“触摸与鼠标：为您的 Unity 游戏选择完美的输入法”：
在Unity中，您可以使用鼠标事件来模拟触摸输入以用于测试和开发目的。 Unity 提供了一组鼠标事件，您可以在 Unity 编辑器或支持触摸输入的设备上运行游戏时使用它们来处理类似触摸的交互。

### 1.2.1可用于触摸模拟的主要鼠标事件包括：
OnMouseDown 鼠标按下时：当在碰撞体（例如 2D 或 3D 对象）上按下鼠标按钮时，将调用此事件。您可以使用它来启动类似触摸的操作。
OnMouseDrag 鼠标拖动时：当按住按钮的同时拖动鼠标时会调用此事件。它对于实现拖动或连续的基于触摸的交互非常有用。
OnMouseUp 鼠标松开时：  当释放鼠标按钮时调用此事件。它用于处理类触摸交互结束时应发生的操作。

```cs
using UnityEngine;

public class TouchSimulation : MonoBehaviour
{
    private bool isDragging = false;

    private void OnMouseDown()
    {
        // Handle the beginning of the touch-like interaction.
        Debug.Log("Touch began over object");
    }

    private void OnMouseDrag()
    {
        // Handle continuous touch-like interaction (e.g., dragging).
        Debug.Log("Dragging the object");

        // You can update the object's position or perform other actions here.
    }

    private void OnMouseUp()
    {
        // Handle the end of the touch-like interaction.
        Debug.Log("Touch ended over object");
    }
}
```

### 1.2.2 触摸事件、鼠标事件和Input.GetMouseButtonDown之间的主要区别如下：
(1). Touch Events 触摸事件：
用途：触摸事件主要用于处理触摸屏设备（例如智能手机和平板电脑）上的触摸输入。
设备：触摸事件是为触摸屏设计的，是在这些设备上处理触摸输入的首选方法。
示例：使用触摸事件移动角色、滑动菜单或捏合放大移动游戏。

(2). Mouse Events 鼠标事件：
用法：鼠标事件（例如“OnMouseDown”、“OnMouseDrag”和“OnMouseUp”）是 Unity 的内置事件函数，用于处理 Unity 编辑器内以及某些情况下独立应用程序中的鼠标交互。这些事件与具有 Collider 组件的游戏对象相关联，通常用于 Unity 编辑器中的测试和开发目的。
设备：鼠标事件是为带有鼠标的传统计算机输入设备而设计的。
示例：使用鼠标事件模拟 Unity 编辑器中的触摸交互或桌面游戏中与基于鼠标的输入的特定交互。

(3). Input.GetMouseButtonDown:
用法：“Input.GetMouseButtonDown”是一种用于检测脚本中鼠标按钮单击的方法。这是一种以编程方式检查鼠标按钮是否已按下的方法。您传递的参数（例如，“0”表示鼠标左键）确定您要检查的鼠标按钮。
Devices设备：此方法适用于传统鼠标设备。
示例：使用“Input.GetMouseButtonDown(0)”检测代码中的鼠标左键单击，允许您根据鼠标按钮输入触发操作。


### 1.2.3 何时使用什么：
Touch Events 触摸事件：
在为移动平台（iOS、Android）进行开发并且您想要处理触摸屏设备上的用户交互时，请使用触摸事件。触摸事件对于在移动设备上提供良好的用户体验至关重要。它们允许您响应各种触摸手势和多点触摸输入。

Mouse Events 鼠标事件：
当您在 Unity 编辑器中工作并想要模拟触摸或鼠标交互以进行测试和开发时，请使用鼠标事件。您还可以将它们用于桌面游戏中的特定交互。

Input.GetMouseButtonDown :
当您需要以编程方式检查脚本中的鼠标按钮点击时，请使用“Input.GetMouseButtonDown”。这对于在 Unity 编辑器和独立应用程序中根据鼠标按钮输入触发操作非常有用。
总之，触摸事件、鼠标事件和“Input.GetMouseButtonDown”之间的选择取决于您的目标平台（移动或桌面）、您想要处理的交互类型以及您是在 Unity 编辑器还是在 Unity 编辑器中 独立应用程序。每种方法都有其特定的用例，选择取决于您的项目的要求。
“Unity UI 中的拖放交互：一个实践示例”

## 1.3.Event System 活动系统：
Unity 中的事件系统是一个管理 Unity 应用程序中输入事件的框架。它是处理鼠标点击、触摸手势、键盘输入等用户交互的关键组件。事件系统对于创建交互式用户界面 (UI) 和游戏交互尤其重要。

以下是有关 Unity Event System事件系统的一些要点：
UI Event Handling 用户界面事件处理：事件系统的主要目的之一是管理与 UI 元素相关的事件。这包括按钮、滑块、文本字段和其他 UI 组件。
Event Interfaces 事件接口： Unity 提供了多个事件接口（如 IPointerClickHandler、IPointerEnterHandler、IDragHandler 等），您可以在脚本中实现这些接口来响应各种用户交互。这些接口是事件系统的一部分。

### 1.3.1 跨平台支持：
事件系统设计为跨不同平台工作，包括 PC、移动设备和 VR 设备。这使您可以创建与各种设备兼容的应用程序。
IBeginDragHandler、IDragHandler 和 IEndDragHandler 是 Unity UI 系统中的接口，用于为 UI 元素创建拖放功能。这些界面主要设计用于与按钮、图像和面板等 UI 元素配合使用。让我们解释每个接口并提供一个简单的示例来说明何时使用它们。

(1) IBeginDragHandler：
Interface接口：UnityEngine.EventSystems.IBeginDragHandler。
用途：此接口用于在单击（或触摸）UI 元素时检测拖动操作的开始。
何时使用：当您想要在用户开始拖动 UI 元素时执行某些设置或初始化时，请使用 IBeginDragHandler。
示例：假设您有一个可拖动的 UI 对象（例如卡片），并且您希望在用户开始拖动它时突出显示它或更改其外观。您可以实现 IBeginDragHandler 来实现此效果。

(2) IDragHandler：
Interface接口：UnityEngine.EventSystems.IDragHandler。
用途：该接口用于检测UI元素的连续拖动。当 UI 元素被拖动时，它会在每一帧被调用。
何时使用：当您想要在拖动操作期间更新 UI 元素的位置或行为时，请使用 IDragHandler。
示例：假设您有一个可拖动窗口，并且您希望它在屏幕上拖动时跟随鼠标或触摸输入。您可以使用 IDragHandler 来更新窗口的位置。

(3) IEndDragHandler：
Interface接口: UnityEngine.EventSystems.IEndDragHandler.
用途：该接口用于检测拖动操作的结束，例如当用户释放鼠标按钮或触摸输入时。
何时使用：当您想要执行任何清理或响应拖动操作的结束时，请使用 IEndDragHandler。
示例：如果您正在创建拖放系统，并希望在将 UI 元素拖放到有效位置时将其对齐到位，则可以实现 IEndDragHandler 来处理此对齐行为。

下面是 Unity 中的一个简单代码示例，使用这些接口来实现基本的可拖动 UI 元素：
```cs
using UnityEngine;
using UnityEngine.EventSystems;

public class DraggableUIElement : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    private RectTransform rectTransform;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        // Initialization when the drag starts.
        // For example, you can change the color or appearance of the UI element.
        Debug.Log("Drag started!");
    }

    public void OnDrag(PointerEventData eventData)
    {
        // Update the position of the UI element during dragging.
        // Move the UI element based on the drag input.
        rectTransform.anchoredPosition += eventData.delta;
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        // Cleanup or response when the drag operation ends.
        // For example, snap the UI element to a specific location.
        Debug.Log("Drag ended!");
    }
}
```
在此示例中，我们实现了三个接口来创建可拖动的 UI 元素。当用户单击并开始拖动 UI 元素时，将调用 OnBeginDrag 来初始化拖动操作。在拖动过程中，OnDrag 会根据用户的输入更新 UI 元素的位置。最后，当用户释放 UI 元素时，将调用 OnEndDrag 进行清理或任何最终操作。
 
==============================================================
# 2.Unity3D 开发中的触摸事件和键盘事件详解
BYCW丶零夜  游戏开发编程教学，交流集聚地：682143601
https://zhuanlan.zhihu.com/p/669856886

##  前言
Unity3D是一款强大的游戏开发引擎，可以用于开发各种类型的游戏，包括PC、移动设备和虚拟现实等平台。在Unity3D开发中，触摸事件和键盘事件是非常重要的交互方式。本文将详细介绍Unity3D开发中的触摸事件和键盘事件，包括技术详解和代码实现。

## 一、触摸事件

### 触摸事件简介
在移动设备上，触摸事件是用户与游戏进行交互的主要方式。Unity3D提供了丰富的触摸事件接口，可以方便地处理触摸屏幕、滑动、缩放等操作。

### 触摸事件的类型
在Unity3D中，常用的触摸事件类型有以下几种：

TouchPhase.Began：触摸开始事件，当手指触摸到屏幕时触发。
TouchPhase.Moved：触摸移动事件，当手指在屏幕上移动时触发。
TouchPhase.Ended：触摸结束事件，当手指离开屏幕时触发。
TouchPhase.Canceled：触摸取消事件，当触摸事件被取消时触发，例如应用程序在后台运行时。

### 触摸事件的代码实现

接下来，我们将通过一个简单的示例来演示如何在Unity3D中处理触摸事件。
首先，在场景中创建一个Cube对象，并添加以下脚本：
```cs
using UnityEngine;

public class TouchTest : MonoBehaviour
{
    void Update()
    {
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);

            if (touch.phase == TouchPhase.Began)
            {
                Debug.Log("Touch began");
            }
            else if (touch.phase == TouchPhase.Moved)
            {
                Debug.Log("Touch moved");
            }
            else if (touch.phase == TouchPhase.Ended)
            {
                Debug.Log("Touch ended");
            }
        }
    }
}
```
在上述代码中，我们通过Input.touchCount来获取当前触摸的手指数量，然后通过Input.GetTouch(0)来获取第一个手指的触摸信息。接着，我们可以根据触摸的阶段（TouchPhase）来执行不同的操作，例如在TouchPhase.Began阶段输出"Touch began"。

保存并运行游戏，当手指触摸到屏幕时，将会在控制台输出相应的信息。

## 二、键盘事件

### 键盘事件简介

键盘事件是在PC平台上常用的交互方式，用户可以通过键盘按键来控制游戏的运行。Unity3D提供了简单易用的键盘事件接口，可以方便地处理键盘按键的事件。

### 键盘事件的类型

在Unity3D中，常用的键盘事件类型有以下几种：

KeyCode.UpArrow：上箭头按键。
KeyCode.DownArrow：下箭头按键。
KeyCode.LeftArrow：左箭头按键。
KeyCode.RightArrow：右箭头按键。
KeyCode.Space：空格键。
KeyCode.A：A键。
KeyCode.B：B键。
...

### 键盘事件的代码实现

接下来，我们将通过一个示例来演示如何在Unity3D中处理键盘事件。

首先，在场景中创建一个Cube对象，并添加以下脚本：
```cs
using UnityEngine;

public class KeyboardTest : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.Log("Space key pressed");
        }
        else if (Input.GetKey(KeyCode.UpArrow))
        {
            Debug.Log("Up arrow key pressed");
        }
        else if (Input.GetKey(KeyCode.DownArrow))
        {
            Debug.Log("Down arrow key pressed");
        }
        else if (Input.GetKey(KeyCode.LeftArrow))
        {
            Debug.Log("Left arrow key pressed");
        }
        else if (Input.GetKey(KeyCode.RightArrow))
        {
            Debug.Log("Right arrow key pressed");
        }
    }
}
```
在上述代码中，我们通过Input.GetKeyDown来判断是否按下了某个按键，例如判断是否按下了空格键。通过Input.GetKey来判断某个按键是否一直被按下，例如判断是否一直按下了上箭头键。

保存并运行游戏，在按下相应的键盘按键时，将会在控制台输出相应的信息。

本文详细介绍了Unity3D开发中的触摸事件和键盘事件，并通过代码示例演示了如何处理触摸事件和键盘事件。在实际开发中，我们可以根据具体需求来处理不同的触摸事件和键盘事件，以实现更加灵活和丰富的交互方式。希望本文对你理解和应用Unity3D开发中的触摸事件和键盘事件有所帮助。