---
title: 数组与链表
weight: 1
---

# 数组与链表面试题

## 1. 两数之和

**问题：** 给定一个整数数组 nums 和一个整数目标值 target，请你在该数组中找出和为目标值 target 的那两个整数，并返回它们的数组下标。

**示例：**
```
输入：nums = [2,7,11,15], target = 9
输出：[0,1]
解释：因为 nums[0] + nums[1] == 9 ，返回 [0, 1] 。
```

**答案：**

```python
def twoSum(nums, target):
    hash_map = {}
    for i, num in enumerate(nums):
        complement = target - num
        if complement in hash_map:
            return [hash_map[complement], i]
        hash_map[num] = i
    return []
```

**复杂度分析：**
- 时间复杂度：O(n)
- 空间复杂度：O(n)

---

## 2. 反转链表

**问题：** 给你单链表的头节点 head ，请你反转链表，并返回反转后的链表。

**示例：**
```
输入：head = [1,2,3,4,5]
输出：[5,4,3,2,1]
```

**答案：**

```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def reverseList(head):
    prev = None
    curr = head
    
    while curr:
        next_temp = curr.next
        curr.next = prev
        prev = curr
        curr = next_temp
    
    return prev
```

**复杂度分析：**
- 时间复杂度：O(n)
- 空间复杂度：O(1)

---

## 3. 合并两个有序数组

**问题：** 给你两个按非递减顺序排列的整数数组 nums1 和 nums2，另有两个整数 m 和 n ，分别表示 nums1 和 nums2 中的元素数目。请你合并 nums2 到 nums1 中，使合并后的数组同样按非递减顺序排列。

**示例：**
```
输入：nums1 = [1,2,3,0,0,0], m = 3, nums2 = [2,5,6], n = 3
输出：[1,2,2,3,5,6]
```

**答案：**

```python
def merge(nums1, m, nums2, n):
    # 从后向前填充
    i = m - 1  # nums1 的末尾
    j = n - 1  # nums2 的末尾
    k = m + n - 1  # 合并后的末尾
    
    while j >= 0:
        if i >= 0 and nums1[i] > nums2[j]:
            nums1[k] = nums1[i]
            i -= 1
        else:
            nums1[k] = nums2[j]
            j -= 1
        k -= 1
```

**复杂度分析：**
- 时间复杂度：O(m + n)
- 空间复杂度：O(1)

---

## 4. 环形链表

**问题：** 给你一个链表的头节点 head ，判断链表中是否有环。

**答案：**

```python
def hasCycle(head):
    if not head or not head.next:
        return False
    
    slow = head
    fast = head.next
    
    while slow != fast:
        if not fast or not fast.next:
            return False
        slow = slow.next
        fast = fast.next.next
    
    return True
```

**复杂度分析：**
- 时间复杂度：O(n)
- 空间复杂度：O(1)

---

## 5. 找出数组中的第K大元素

**问题：** 给定整数数组 nums 和整数 k，请返回数组中第 k 个最大的元素。

**示例：**
```
输入: [3,2,1,5,6,4] 和 k = 2
输出: 5
```

**答案：**

```python
import heapq

def findKthLargest(nums, k):
    # 使用最小堆
    min_heap = nums[:k]
    heapq.heapify(min_heap)
    
    for num in nums[k:]:
        if num > min_heap[0]:
            heapq.heapreplace(min_heap, num)
    
    return min_heap[0]

# 或者使用快速选择算法
def findKthLargest_quickselect(nums, k):
    def partition(left, right, pivot_idx):
        pivot = nums[pivot_idx]
        # 将 pivot 移到末尾
        nums[pivot_idx], nums[right] = nums[right], nums[pivot_idx]
        store_idx = left
        
        for i in range(left, right):
            if nums[i] < pivot:
                nums[store_idx], nums[i] = nums[i], nums[store_idx]
                store_idx += 1
        
        # 将 pivot 放到正确位置
        nums[right], nums[store_idx] = nums[store_idx], nums[right]
        return store_idx
    
    def select(left, right, k_smallest):
        if left == right:
            return nums[left]
        
        pivot_idx = (left + right) // 2
        pivot_idx = partition(left, right, pivot_idx)
        
        if k_smallest == pivot_idx:
            return nums[k_smallest]
        elif k_smallest < pivot_idx:
            return select(left, pivot_idx - 1, k_smallest)
        else:
            return select(pivot_idx + 1, right, k_smallest)
    
    return select(0, len(nums) - 1, len(nums) - k)
```

**复杂度分析：**
- 堆方法：时间 O(n log k)，空间 O(k)
- 快速选择：平均时间 O(n)，最坏 O(n²)，空间 O(1)
