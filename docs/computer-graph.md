# 1.B样条曲线

### **B样条曲线（B-Spline Curve）详解**

B样条曲线（B-Spline）是计算机图形学、CAD/CAM和几何建模中广泛使用的参数化曲线，相比贝塞尔曲线（Bezier Curve），它具有更强的局部控制能力和灵活性。以下是其核心概念和数学原理的清晰解释：

---

## **1. 基本概念**
### **（1）定义**
B样条曲线由一组**控制点（Control Points）**、一个**节点向量（Knot Vector）**和**基函数（Basis Functions）**组成，其数学表达式为：
\[
C(u) = \sum_{i=0}^{n} N_{i,p}(u) \cdot P_i
\]
- \( P_i \)：第 \( i \) 个控制点（共 \( n+1 \) 个）。
- \( N_{i,p}(u) \)：第 \( i \) 个 \( p \) 次（阶数为 \( p+1 \)）B样条基函数。
- \( u \)：参数（通常归一化到 \([0,1]\)）。

### **（2）核心特点**
- **局部支持性**：每个控制点仅影响曲线的一部分（由基函数的非零区间决定）。
- **灵活阶数**：可通过调整阶数（\( p \)）控制曲线的光滑性（如 \( p=2 \) 为二次B样条）。
- **节点向量**：决定参数 \( u \) 如何映射到曲线段。

---

## **2. 关键组成部分**
### **（1）节点向量（Knot Vector）**
节点向量是一组非递减序列 \( U = \{u_0, u_1, ..., u_{m}\} \)，其中 \( m = n + p + 1 \)。  
- **均匀B样条**：节点等距分布（如 \( U = \{0,1,2,3,4\} \)）。
- **非均匀B样条**：节点不等距（允许更复杂的曲线形状）。

### **（2）基函数（Basis Functions）**
基函数 \( N_{i,p}(u) \) 通过递归公式（Cox-de Boor公式）定义：
\[
\begin{cases}
N_{i,0}(u) = 
\begin{cases}
1 & \text{if } u_i \leq u < u_{i+1} \\
0 & \text{otherwise}
\end{cases} \\
N_{i,p}(u) = \frac{u - u_i}{u_{i+p} - u_i} N_{i,p-1}(u) + \frac{u_{i+p+1} - u}{u_{i+p+1} - u_{i+1}} N_{i+1,p-1}(u)
\end{cases}
\]

---

## **3. B样条曲线的类型**
### **（1）开放（Open）B样条**
- **特点**：曲线通过第一个和最后一个控制点。
- **节点向量**：首尾节点重复 \( p+1 \) 次（如 \( U = \{0,0,0,1,2,3,3,3\} \) 对应 \( p=2 \)）。

### **（2）闭合（Closed）B样条**
- **特点**：曲线首尾相连（周期性）。
- **实现方式**：控制点循环（\( P_0 = P_n \)）或使用周期性节点向量。

### **（3）均匀 vs 非均匀**
| **类型**       | **节点分布**       | **应用场景**               |
|----------------|--------------------|---------------------------|
| 均匀B样条      | 节点等距（如 0,1,2,3） | 简单平滑曲线              |
| 非均匀B样条（NURBS） | 节点不等距          | 复杂形状（如汽车曲面设计） |

---

## **4. B样条 vs 贝塞尔曲线**
| **特性**          | **B样条曲线**                  | **贝塞尔曲线**              |
|-------------------|-------------------------------|----------------------------|
| **局部控制**      | ✅ 是（修改一个点不影响全局）   | ❌ 否（全局修改）           |
| **阶数灵活性**    | ✅ 可自由选择（如2次、3次）     | ❌ 阶数=控制点数-1          |
| **节点向量**      | ✅ 需要定义                    | ❌ 不需要                  |
| **计算复杂度**    | ⚠️ 较高（递归基函数）          | ✅ 较低（伯恩斯坦多项式）   |

---

## **5. 代码实现（C++示例）**
以下是一个简单的二次B样条曲线生成代码（使用OpenSceneGraph的 `osg::Vec3Array`）：
```cpp
#include <vector>
#include <osg/Vec3d>

// Cox-de Boor 基函数计算
double N(int i, int p, double u, const std::vector<double>& knots) {
    if (p == 0) {
        return (u >= knots[i] && u < knots[i+1]) ? 1.0 : 0.0;
    }
    double denom1 = knots[i+p] - knots[i];
    double denom2 = knots[i+p+1] - knots[i+1];
    double term1 = (denom1 != 0) ? (u - knots[i]) / denom1 * N(i, p-1, u, knots) : 0;
    double term2 = (denom2 != 0) ? (knots[i+p+1] - u) / denom2 * N(i+1, p-1, u, knots) : 0;
    return term1 + term2;
}

// 生成B样条曲线点
osg::Vec3Array* generateBSpline(
    const std::vector<osg::Vec3d>& controlPoints,
    const std::vector<double>& knots,
    int p,
    int samplePoints = 100) {
    
    osg::Vec3Array* curve = new osg::Vec3Array;
    double uMin = knots[p];
    double uMax = knots[knots.size() - p - 1];
    double step = (uMax - uMin) / samplePoints;

    for (double u = uMin; u <= uMax; u += step) {
        osg::Vec3d point(0, 0, 0);
        for (int i = 0; i < controlPoints.size(); ++i) {
            point += controlPoints[i] * N(i, p, u, knots);
        }
        curve->push_back(point);
    }
    return curve;
}
```

---

## **6. 应用场景**
- **CAD/CAM设计**：汽车/飞机曲面建模（NURBS是B样条的推广）。
- **动画路径**：平滑的相机运动轨迹（如 `osg::AnimationPath`）。
- **地理信息系统（GIS）**：河流、道路的平滑绘制。

---

## **总结**
- **B样条曲线**通过**控制点**、**节点向量**和**基函数**定义，支持局部控制和灵活阶数。
- **节点向量**决定参数化方式，**基函数**通过递归计算。
- 相比贝塞尔曲线，B样条更适合复杂形状和局部编辑。
- 在OSG中可通过自定义基函数生成曲线，或直接使用 `osg::NURBS` 类（支持NURBS曲面）。

=================================================
# 2. **NURBS（非均匀有理B样条）详解**

NURBS（Non-Uniform Rational B-Spline）是B样条曲线的推广，在计算机图形学、CAD/CAM和工业设计中广泛应用。它结合了B样条的灵活性和有理函数的表达能力，能够精确表示圆锥曲线等复杂形状。

---

## **1. NURBS基本概念**

### **（1）数学定义**
NURBS曲线的数学表达式为：
\[
C(u) = \frac{\sum_{i=0}^{n} N_{i,p}(u) \cdot w_i \cdot P_i}{\sum_{i=0}^{n} N_{i,p}(u) \cdot w_i}
\]
其中：
- \( P_i \)：控制点（Control Points）
- \( w_i \)：权重（Weights）
- \( N_{i,p}(u) \)：p次B样条基函数
- \( u \)：参数

### **（2）核心组件**
| **组件** | **作用** | **特点** |
|---------|---------|----------|
| **控制点** \( P_i \) | 定义曲线的大致形状 | 不一定要在曲线上 |
| **权重** \( w_i \) | 控制点的"吸引力" | \( w_i > 0 \)，权重越大，曲线越靠近该点 |
| **节点向量** | 定义参数化方式 | 非均匀分布，支持局部控制 |
| **基函数** | 混合控制点 | 递归计算（Cox-de Boor算法） |

---

## **2. NURBS vs B样条**

### **关键区别**
```cpp
// B样条（无权重的特殊情况）
C(u) = Σ[N_i,p(u) * P_i]

// NURBS（带权重的推广）
C(u) = Σ[N_i,p(u) * w_i * P_i] / Σ[N_i,p(u) * w_i]
```

### **能力对比**
| **特性** | **B样条** | **NURBS** |
|----------|-----------|-----------|
| 表示圆锥曲线 | ❌ 不能 | ✅ 能（圆、椭圆、双曲线） |
| 权重控制 | ❌ 无 | ✅ 有 |
| 精确表示 | 只能近似 | 精确表示 |
| 计算复杂度 | 较低 | 较高 |

---

## **3. NURBS的重要性质**

### **（1）局部支持性**
- 每个控制点只影响局部曲线段
- 修改一个点不会改变整个曲线

### **（2）仿射不变性**
- 对控制点进行仿射变换等价于对整个曲线进行变换

### **（3）强凸包性**
- 曲线位于控制点凸包内
- 权重影响曲线的"紧致度"

### **（4）变差减少性**
- 不会出现意外的波动

---

## **4. NURBS曲面**

### **数学定义**
NURBS曲面是双参数曲面：
\[
S(u,v) = \frac{\sum_{i=0}^{n} \sum_{j=0}^{m} N_{i,p}(u) N_{j,q}(v) w_{i,j} P_{i,j}}{\sum_{i=0}^{n} \sum_{j=0}^{m} N_{i,p}(u) N_{j,q}(v) w_{i,j}}
\]

### **控制网格**
```cpp
// 控制点网格示例
osg::Vec3Array* controlPoints = new osg::Vec3Array;
for (int i = 0; i <= n; ++i) {
    for (int j = 0; j <= m; ++j) {
        controlPoints->push_back(osg::Vec3(i, j, 0));
    }
}
```

---

## **5. 代码实现（C++/OSG示例）**

### **（1）基础NURBS曲线类**
```cpp
#include <vector>
#include <osg/Vec3d>

class NURBSCurve {
private:
    std::vector<osg::Vec3d> _controlPoints;
    std::vector<double> _weights;
    std::vector<double> _knots;
    int _degree;
    
public:
    NURBSCurve(int degree = 3) : _degree(degree) {}
    
    // 设置控制点和权重
    void setControlPoints(const std::vector<osg::Vec3d>& points, 
                         const std::vector<double>& weights) {
        _controlPoints = points;
        _weights = weights;
        generateKnotVector();
    }
    
    // 生成节点向量
    void generateKnotVector() {
        int n = _controlPoints.size() - 1;
        int m = n + _degree + 1;
        _knots.clear();
        
        // 均匀节点向量（可扩展为非均匀）
        for (int i = 0; i <= m; ++i) {
            _knots.push_back(static_cast<double>(i) / m);
        }
    }
    
    // Cox-de Boor基函数
    double basisFunction(int i, int p, double u) const {
        if (p == 0) {
            return (u >= _knots[i] && u < _knots[i+1]) ? 1.0 : 0.0;
        }
        
        double denom1 = _knots[i+p] - _knots[i];
        double denom2 = _knots[i+p+1] - _knots[i+1];
        
        double term1 = (denom1 != 0) ? 
            (u - _knots[i]) / denom1 * basisFunction(i, p-1, u) : 0;
        double term2 = (denom2 != 0) ? 
            (_knots[i+p+1] - u) / denom2 * basisFunction(i+1, p-1, u) : 0;
            
        return term1 + term2;
    }
    
    // 计算曲线点
    osg::Vec3d evaluate(double u) const {
        double denominator = 0.0;
        osg::Vec3d numerator(0, 0, 0);
        
        for (int i = 0; i < _controlPoints.size(); ++i) {
            double basis = basisFunction(i, _degree, u);
            double weightedBasis = basis * _weights[i];
            
            denominator += weightedBasis;
            numerator += _controlPoints[i] * weightedBasis;
        }
        
        return denominator != 0 ? numerator / denominator : osg::Vec3d(0, 0, 0);
    }
    
    // 生成曲线点集
    osg::Vec3Array* generateCurve(int samples = 100) const {
        osg::Vec3Array* curve = new osg::Vec3Array;
        double uMin = _knots[_degree];
        double uMax = _knots[_knots.size() - _degree - 1];
        
        for (int i = 0; i <= samples; ++i) {
            double u = uMin + (uMax - uMin) * i / samples;
            curve->push_back(evaluate(u));
        }
        return curve;
    }
};
```

### **（2）创建圆形NURBS曲线**
```cpp
// 创建精确的圆形（NURBS特性）
NURBSCurve createCircle(double radius = 1.0, osg::Vec3d center = osg::Vec3d(0,0,0)) {
    NURBSCurve curve(2); // 二次曲线表示圆
    
    // 9个控制点定义圆（权重精确控制）
    std::vector<osg::Vec3d> points;
    std::vector<double> weights;
    
    double angleStep = osg::PI / 4; // 45度间隔
    
    for (int i = 0; i < 9; ++i) {
        double angle = i * angleStep;
        points.push_back(center + osg::Vec3d(cos(angle), sin(angle), 0) * radius);
        
        // 权重设置：控制点1,3,5,7权重为√2/2，其他为1
        weights.push_back((i % 2 == 1) ? sqrt(2)/2 : 1.0);
    }
    
    curve.setControlPoints(points, weights);
    return curve;
}
```

---

## **6. 在OSG中的使用**

### **（1）使用osg::NURBS类**
```cpp
#include <osg/Geometry>
#include <osg/ShapeDrawable>

osg::Geode* createNURBSSurface() {
    osg::Geode* geode = new osg::Geode;
    osg::Geometry* geometry = new osg::Geometry;
    
    // 创建NURBS曲面数据
    osg::Vec3Array* vertices = new osg::Vec3Array;
    osg::Vec3Array* normals = new osg::Vec3Array;
    
    // 生成曲面点（实际应用中使用专业NURBS库）
    int uSamples = 50, vSamples = 50;
    for (int i = 0; i <= uSamples; ++i) {
        double u = static_cast<double>(i) / uSamples;
        for (int j = 0; j <= vSamples; ++j) {
            double v = static_cast<double>(j) / vSamples;
            
            // 示例：简单曲面
            double x = u * 10 - 5;
            double y = v * 10 - 5;
            double z = sin(u * osg::PI * 2) * cos(v * osg::PI * 2);
            
            vertices->push_back(osg::Vec3(x, y, z));
            normals->push_back(osg::Vec3(0, 0, 1)); // 简化法线计算
        }
    }
    
    geometry->setVertexArray(vertices);
    geometry->setNormalArray(normals);
    geometry->setNormalBinding(osg::Geometry::BIND_PER_VERTEX);
    
    // 创建三角网格
    for (int i = 0; i < uSamples; ++i) {
        for (int j = 0; j < vSamples; ++j) {
            osg::DrawElementsUInt* quad = new osg::DrawElementsUInt(osg::PrimitiveSet::QUADS, 4);
            (*quad)[0] = i * (vSamples + 1) + j;
            (*quad)[1] = (i + 1) * (vSamples + 1) + j;
            (*quad)[2] = (i + 1) * (vSamples + 1) + j + 1;
            (*quad)[3] = i * (vSamples + 1) + j + 1;
            geometry->addPrimitiveSet(quad);
        }
    }
    
    geode->addDrawable(geometry);
    return geode;
}
```

---

## **7. 应用场景**

### **（1）工业设计**
- 汽车、飞机曲面建模
- 产品外观设计

### **（2）计算机图形学**
- 3D建模软件（Blender、Maya）
- 动画角色建模

### **（3）地理信息系统**
- 地形曲面建模
- 建筑信息模型（BIM）

### **（4）科学计算**
- 等值面绘制
- 数据可视化

---

## **8. 优缺点总结**

### **优点**
- ✅ 精确表示圆锥曲线和自由曲面
- ✅ 统一的数学表示（点、线、面、体）
- ✅ 强大的局部控制能力
- ✅ 工业标准（IGES、STEP格式支持）

### **缺点**
- ❌ 计算复杂度较高
- ❌ 需要专业理解才能有效使用
- ❌ 存储需求较大（控制点+权重+节点）

---

## **总结**
NURBS是计算机图形学中的重要工具，通过**有理权重**扩展了B样条的能力，能够精确表示从简单圆形到复杂汽车曲面的各种形状。在OSG中，虽然内置支持有限，但可以通过自定义实现或第三方库（如OpenNURBS）来创建高质量的NURBS几何体。

==================================================
# 3.Nurbs 和贝塞尔曲线

# **NURBS vs 贝塞尔曲线：全面对比**

## **1. 基本概念对比**

### **贝塞尔曲线（Bézier Curve）**
```cpp
// n次贝塞尔曲线公式
C(t) = Σ[i=0 to n] (B_i,n(t) * P_i)
// 其中伯恩斯坦基函数：
B_i,n(t) = C(n,i) * t^i * (1-t)^(n-i)
```

### **NURBS曲线**
```cpp
// NURBS曲线公式
C(u) = Σ[i=0 to n] (N_i,p(u) * w_i * P_i) / Σ[i=0 to n] (N_i,p(u) * w_i)
```

---

## **2. 数学特性对比**

| **特性** | **贝塞尔曲线** | **NURBS** |
|---------|---------------|-----------|
| **基函数** | 伯恩斯坦多项式 | B样条基函数 |
| **参数范围** | t ∈ [0, 1] | u ∈ [节点向量范围] |
| **控制点影响** | 全局影响 | 局部影响 |
| **表示能力** | 多项式曲线 | 有理多项式曲线 |

---

## **3. 控制点行为差异**

### **贝塞尔曲线：全局控制**
```cpp
// 修改任意控制点影响整个曲线
vector<Point> bezierPoints = {P0, P1, P2, P3}; // 三次贝塞尔
// 移动P1会影响整个曲线形状
```

### **NURBS：局部控制**
```cpp
// 修改控制点只影响局部区域
vector<Point> nurbsPoints = {P0, P1, P2, P3, P4, P5};
vector<double> knots = {0,0,0,1,2,3,3,3}; // 二次NURBS
// 移动P2只影响u∈[0,2]区间
```

---

## **4. 曲线连续性对比**

### **贝塞尔曲线连续性**
```cpp
// 单段贝塞尔：C∞连续
// 多段拼接：需要特殊处理保证连续性

// 示例：两段三次贝塞尔曲线C1连续条件
BezierCurve segment1(P0, P1, P2, P3);
BezierCurve segment2(P3, P4, P5, P6);
// C1连续条件：P3-P2 = P4-P3（切线方向一致）
```

### **NURBS连续性**
```cpp
// 自动保证Cp-k连续，其中k是节点重复度
vector<double> knots = {0,0,0,1,1,2,2,2}; // 在u=1处C0连续
// 节点重复度=2，连续性=C(p-2)
```

---

## **5. 精确表示能力**

### **贝塞尔曲线的局限**
```cpp
// 无法精确表示圆锥曲线
// 圆只能用多段贝塞尔近似
vector<BezierCurve> circleSegments; // 需要4段三次贝塞尔近似圆
```

### **NURBS的优势**
```cpp
// 精确表示圆锥曲线
NURBSCurve exactCircle = createCircle(radius, center);
// 通过权重控制曲线类型：
// w = 1 → 抛物线
// w = √2/2 → 圆、椭圆
// w > 1 → 双曲线
```

---

## **6. 代码实现对比**

### **贝塞尔曲线实现**
```cpp
class BezierCurve {
private:
    vector<Point> controlPoints;
    
public:
    Point evaluate(double t) {
        Point result(0, 0, 0);
        int n = controlPoints.size() - 1;
        
        for (int i = 0; i <= n; i++) {
            double basis = binomial(n, i) * pow(t, i) * pow(1-t, n-i);
            result += controlPoints[i] * basis;
        }
        return result;
    }
    
    // 德卡斯特里奥算法（更稳定）
    Point deCasteljau(double t) {
        vector<Point> points = controlPoints;
        for (int k = 1; k <= points.size()-1; k++) {
            for (int i = 0; i < points.size()-k; i++) {
                points[i] = points[i] * (1-t) + points[i+1] * t;
            }
        }
        return points[0];
    }
};
```

### **NURBS实现**
```cpp
class NURBSCurve {
private:
    vector<Point> controlPoints;
    vector<double> weights;
    vector<double> knots;
    int degree;
    
public:
    Point evaluate(double u) {
        double denominator = 0.0;
        Point numerator(0, 0, 0);
        
        for (int i = 0; i < controlPoints.size(); i++) {
            double basis = coxDeBoor(i, degree, u);
            double weightedBasis = basis * weights[i];
            
            denominator += weightedBasis;
            numerator += controlPoints[i] * weightedBasis;
        }
        return numerator / denominator;
    }
    
    double coxDeBoor(int i, int p, double u) {
        if (p == 0) {
            return (u >= knots[i] && u < knots[i+1]) ? 1.0 : 0.0;
        }
        
        double term1 = 0, term2 = 0;
        double denom1 = knots[i+p] - knots[i];
        double denom2 = knots[i+p+1] - knots[i+1];
        
        if (denom1 != 0) {
            term1 = (u - knots[i]) / denom1 * coxDeBoor(i, p-1, u);
        }
        if (denom2 != 0) {
            term2 = (knots[i+p+1] - u) / denom2 * coxDeBoor(i+1, p-1, u);
        }
        
        return term1 + term2;
    }
};
```

---

## **7. 几何特性对比**

| **特性** | **贝塞尔曲线** | **NURBS** |
|---------|---------------|-----------|
| **凸包性** | 严格在凸包内 | 在控制点凸包内 |
| **变差减少** | ✅ 是 | ✅ 是 |
| **仿射不变性** | ✅ 是 | ✅ 是 |
| **节点插入** | ❌ 困难 | ✅ 容易 |

---

## **8. 应用场景对比**

### **贝塞尔曲线适用场景**
```cpp
// 1. 简单图形设计
BezierCurve simpleShape; // 图标、LOGO设计

// 2. 字体轮廓
TrueTypeFont glyph; // 使用二次贝塞尔曲线

// 3. 动画路径
AnimationPath path; // 简单的相机运动

// 4. UI设计
RoundedRectangle button; // 圆角矩形
```

### **NURBS适用场景**
```cpp
// 1. 工业设计
CarBodySurface design; // 汽车、飞机曲面

// 2. 精密制造
AerospaceComponents parts; // 航空零件

// 3. 建筑信息模型
BIMModel building; // 复杂建筑曲面

// 4. 科学计算
CADModel precisionModel; // 高精度模型
```

---

## **9. 性能与复杂度**

### **计算复杂度**
```cpp
// 贝塞尔曲线：O(n)每次求值
Point bezierValue = bezier.evaluate(t); // 直接计算

// NURBS：O(p²)每次求值（递归基函数）
Point nurbsValue = nurbs.evaluate(u); // 递归计算
```

### **内存需求**
```cpp
struct BezierData {
    vector<Point> controlPoints; // 只需要控制点
};

struct NURBSData {
    vector<Point> controlPoints;
    vector<double> weights;     // 额外权重
    vector<double> knots;       // 额外节点向量
    int degree;                 // 阶数信息
};
```

---

## **10. 相互关系和转换**

### **贝塞尔是NURBS的特例**
```cpp
// 当满足以下条件时，NURBS退化为贝塞尔曲线：
vector<double> weights(controlPoints.size(), 1.0); // 所有权重=1
vector<double> knots = {0,0,0,0,1,1,1,1}; // 三次贝塞尔对应节点向量
// → 此时NURBS = 贝塞尔曲线
```

### **贝塞尔转NURBS**
```cpp
NURBSCurve bezierToNURBS(const BezierCurve& bezier) {
    NURBSCurve nurbs;
    nurbs.controlPoints = bezier.controlPoints;
    nurbs.weights.assign(bezier.controlPoints.size(), 1.0);
    nurbs.degree = bezier.controlPoints.size() - 1;
    
    // 生成节点向量：首尾重复degree+1次
    for (int i = 0; i <= nurbs.degree; i++) {
        nurbs.knots.push_back(0.0);
    }
    for (int i = 0; i <= nurbs.degree; i++) {
        nurbs.knots.push_back(1.0);
    }
    
    return nurbs;
}
```

---

## **11. 总结表格**

| **比较维度** | **贝塞尔曲线** | **NURBS** | **胜出方** |
|------------|---------------|-----------|-----------|
| **简单性** | ✅ 简单直观 | ❌ 复杂 | 贝塞尔 |
| **局部控制** | ❌ 全局影响 | ✅ 局部控制 | NURBS |
| **连续性** | ❌ 拼接复杂 | ✅ 自动连续 | NURBS |
| **精确表示** | ❌ 只能近似 | ✅ 精确表示 | NURBS |
| **计算效率** | ✅ 高效 | ❌ 较慢 | 贝塞尔 |
| **工业应用** | ❌ 有限 | ✅ 广泛 | NURBS |
| **灵活性** | ❌ 固定阶数 | ✅ 可变阶数 | NURBS |

---

## **12. 选择建议**

### **使用贝塞尔曲线当：**
- 需要简单快速的曲线实现
- 控制点数量较少（通常<10个）
- 不需要局部编辑
- 实时性能要求高

### **使用NURBS当：**
- 需要精确的工业级曲线
- 需要局部控制编辑
- 处理复杂曲面建模
- 需要与其他CAD系统交换数据

两者不是替代关系，而是**互补关系**。在实际应用中，经常在高层使用NURBS进行精确建模，在底层使用贝塞尔进行高效渲染。