---
title: JavaScript 面试题
weight: 1
---

# JavaScript 面试题

## 1. 什么是闭包？

**问题：** 请解释什么是闭包，并给出一个实际应用的例子。

**答案：**

闭包是指有权访问另一个函数作用域中的变量的函数。创建闭包的常见方式，就是在一个函数内部创建另一个函数。

```javascript
function createCounter() {
  let count = 0;
  return {
    increment: function() {
      count++;
      return count;
    },
    decrement: function() {
      count--;
      return count;
    },
    getCount: function() {
      return count;
    }
  };
}

const counter = createCounter();
console.log(counter.increment()); // 1
console.log(counter.increment()); // 2
console.log(counter.getCount());  // 2
```

**应用场景：**
- 数据封装和私有变量
- 函数柯里化
- 防抖和节流函数

---

## 2. var、let 和 const 的区别

**问题：** 请说明 var、let 和 const 的区别。

**答案：**

| 特性 | var | let | const |
|------|-----|-----|-------|
| 作用域 | 函数作用域 | 块级作用域 | 块级作用域 |
| 变量提升 | 有 | 无（暂时性死区） | 无（暂时性死区） |
| 重复声明 | 允许 | 不允许 | 不允许 |
| 重新赋值 | 可以 | 可以 | 不可以 |
| 必须初始化 | 否 | 否 | 是 |

---

## 3. 事件循环机制

**问题：** 请解释 JavaScript 的事件循环机制。

**答案：**

JavaScript 是单线程语言，事件循环是其异步编程的核心机制。

**执行顺序：**
1. 同步代码在主线程执行
2. 异步任务放入任务队列
3. 当主线程空闲时，从任务队列取出任务执行

**宏任务与微任务：**
- **宏任务**：setTimeout、setInterval、I/O、UI 渲染
- **微任务**：Promise.then、MutationObserver、process.nextTick

执行顺序：同步代码 → 微任务 → 宏任务

---

## 4. 原型和原型链

**问题：** 解释 JavaScript 中的原型和原型链。

**答案：**

每个 JavaScript 对象都有一个内部属性 `[[Prototype]]`，指向它的原型对象。当访问对象的属性时，如果对象本身没有该属性，就会沿着原型链向上查找。

```javascript
function Person(name) {
  this.name = name;
}

Person.prototype.greet = function() {
  console.log(`Hello, I'm ${this.name}`);
};

const person = new Person('Alice');
person.greet(); // Hello, I'm Alice

console.log(person.__proto__ === Person.prototype); // true
console.log(Person.prototype.__proto__ === Object.prototype); // true
```

---

## 5. this 指向

**问题：** JavaScript 中 this 的指向规则有哪些？

**答案：**

1. **默认绑定**：全局上下文，this 指向 window（严格模式为 undefined）
2. **隐式绑定**：作为对象方法调用，this 指向该对象
3. **显式绑定**：call、apply、bind 方法改变 this 指向
4. **new 绑定**：构造函数中的 this 指向新创建的实例
5. **箭头函数**：没有自己的 this，继承外层作用域的 this
