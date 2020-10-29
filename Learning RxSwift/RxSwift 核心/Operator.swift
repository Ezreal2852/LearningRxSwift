//
//  Operator.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Operator

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
