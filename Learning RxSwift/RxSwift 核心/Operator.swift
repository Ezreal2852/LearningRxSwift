//
//  Operator.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Combining Operators（连接运算符）

// MARK: zip

func testZip() {
    
    /// 合成操作符，将多个序列合成一个序列，结果序列的元素为前面多个序列元素的元祖
    /// 最多支持8个，可能是因为实在写不下了。。
    
    let titles: Observable<String> = Observable.create { (ob) -> Disposable in
        ob.onNext("title 1")
        ob.onNext("title 2")
        ob.onNext("title 3")
        /// 第四个title没有与之合成的content，所以最终articles只有三个元素。
        ob.onNext("title 4")
        return Disposables.create()
    }
    
    let contents: Observable<String> = Observable.create { (ob) -> Disposable in
        ob.onNext("content 1")
        ob.onNext("content 2")
        ob.onNext("content 3")
        return Disposables.create()
    }
    
    let articles: Observable<(String, String)> = Observable.zip(titles, contents)
    
    articles
        .subscribe(onNext: { print("article title: \($0.0), content: \($0.1)") })
        .disposed(by: disposeBag)
    
    /// 适用场景：我们需要多个对象统一处理，但是又不便或不必要引入新的对象来包含需处理的多个对象
}

// MARK: merge

func testMerge() {
    
    /**
     合成多个Observable，一次可以订阅全部的event，但不压缩元素，仅按发送顺序监听
     */
    
    let subject1 = PublishSubject<String>()
    let subject2 = PublishSubject<String>()
    
    Observable.merge(subject1, subject2)
        .debug()
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
    
    subject1.onNext("🅰️")
    subject1.onNext("🅱️")
    subject2.onNext("①")
    subject2.onNext("②")
    subject1.onNext("🆎")
    subject2.onNext("③")
}

// MARK: combineLatest

func testCombineLatest() {
    
    /**
     合并多个序列最后一个元素
     多个序列至少都有一个元素才发送event
     当任何一个源可观察序列发出时，将从合并的可观察序列中开始发射每个源可观察序列的最新元素 序列发出一个新元素
     */
    
    let stringSubject = PublishSubject<String>()
    let intSubject = PublishSubject<Int>()
    
    Observable.combineLatest(stringSubject, intSubject) { stringElement, intElement in
        "\(stringElement) \(intElement)"
    }
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)
    
    stringSubject.onNext("🅰️")
    stringSubject.onNext("🅱️")
    
    intSubject.onNext(1)
    intSubject.onNext(2)
    
    stringSubject.onNext("🆎")
    
    let stringObservable = Observable.just("❤️")
    let fruitObservable = Observable.from(["🍎", "🍐", "🍊"])
    let animalObservable = Observable.of("🐶", "🐱", "🐭", "🐹")
    
    Observable.combineLatest([stringObservable, fruitObservable, animalObservable]) {
        "\($0[0]) \($0[1]) \($0[2])"
    }
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)
}

// MARK: switchLatest

func testSwitchLatest() {
    
    /// 将可观察序列发出的元素转换为可观察序列，并从最近的内部可观察序列中发出元素。
    
    let subject1 = BehaviorSubject(value: "⚽️")
    let subject2 = BehaviorSubject(value: "🍎")
    
    let subjectsSubject = BehaviorSubject(value: subject1)
    
    subjectsSubject.asObservable()
        .switchLatest()
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
    
    subject1.onNext("🏈")
    subject1.onNext("🏀")
    
    subjectsSubject.onNext(subject2)
    
    /// subjectsSubject已经是subject2了，所以⚾️没有被订阅
    subject1.onNext("⚾️")
    
    subject2.onNext("🍐")
}

// MARK: - Transforming Operators（转化运算符）

// MARK: map

func testMap() {
    
    /// 转换操作符，将原序列元素转换成另一种元素的序列，和Collection.map用法一样的
    
    let numbers: Observable<Int> = Observable.create { (ob) -> Disposable in
        ob.onNext(0)
        ob.onNext(1)
        ob.onNext(2)
        return Disposables.create()
    }
    
    let strings: Observable<String> = numbers.map { String($0) }
    
    strings.subscribe(onNext: { print("str: \($0)") }).disposed(by: disposeBag)
}

// MARK: flatMap & flatMapLastest

func testFlatMap() {
    
    /// flatMapLatest = map + switchLatest
    
    struct Player {
        init(score: Int) {
            self.score = BehaviorSubject(value: score)
        }
        
        let score: BehaviorSubject<Int>
    }
    
    let 👦🏻 = Player(score: 80)
    let 👧🏼 = Player(score: 90)
    
    let player = BehaviorSubject(value: 👦🏻)
    
    player.asObservable()
        .flatMap { $0.score.asObservable() }
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
    
    👦🏻.score.onNext(85)
    
    player.onNext(👧🏼)
    
    /// 如果是flatMapLatest，95将不会被监听
    👦🏻.score.onNext(95)
    
    👧🏼.score.onNext(100)
}

// MARK: scan

func testScan() {
    /// 入参并扫描序列中所有的元素
    /// 和Collection.reduce()比较类似，第二个入参是第一个返回的结果
    Observable.of(10, 100, 1000, 10000)
        .scan(1) { aggregateValue, newValue in
            aggregateValue + newValue
    }
    .debug()
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)
}

// MARK: - Filtering and Conditional Operators（过滤与条件运算符）

// MARK: filter

func testFilter() {
    
    /// 过滤操作符，当predicate: (Element) -> Bool，返回值为true则通过，反之忽视，和Collection.filter用法一样的
    
    let temperatures: Observable<Double> = Observable.create { (ob) -> Disposable in
        ob.onNext(1)
        ob.onNext(50)
        ob.onNext(100)
        return Disposables.create()
    }
    
    temperatures.filter { $0 > 33 }
        .subscribe(onNext: { print("高温：\($0)度") })
        .disposed(by: disposeBag)
}
