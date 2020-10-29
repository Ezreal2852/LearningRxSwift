//
//  Disposable.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Disposable

func testDisposable() {
    
    var disposable: Disposable?
    let textField = UITextField()
    
    /**
     如果一个序列发出了error或者completed事件，那么所有内部资源会被释放。
     如果需要主动释放，则需要调用dispose了，例子如下：
     */
    
    /// 界面显示
    func viewWillAppear(_ animated: Bool) {
        /// 绑定订阅输入框内容和打印内容
        disposable = textField.rx.text.orEmpty
            .subscribe(onNext: { text in print(text) })
    }
    
    /// 界面消失
    func viewWillDisappear(_ animated: Bool) {
        /// 主动解除绑定
        disposable?.dispose()
    }
}

// MARK: DisposeBag

func testDisposeBag() {
    
    /// Swift的中，我们的内存管理是通过ARC，那么如何应用到RX中呢？
    /// 如果disposeBag作为VC的属性，那么当VC释放时，disposeBag也会被释放
    
    var disposeBag = DisposeBag()
    let textField = UITextField()
    
    /// 界面显示
    func viewWillAppear(_ animated: Bool) {
        /// 绑定订阅输入框内容和打印内容，并根据disposeBag的释放来解除绑定
        textField.rx.text.orEmpty
            .subscribe(onNext: { text in print(text) })
            .disposed(by: disposeBag)
    }
    
    /// 界面消失
    func viewWillDisappear(_ animated: Bool) {
        /// 覆盖赋值，释放上一个disposeBag对象，解除disposed(by: 释放的bag)的绑定关系
        disposeBag = DisposeBag()
    }
    
    /// 因为disposed(by:）会插入到由bag管理的[Disposable]中
    /// 然后当DisposeBag释放时，deinit()方法调用全部[Disposable].dispose()
}

// MARK: takeUntil

func testTakeUntil() {
    
    /// 假设：我们要在vc加载后，绑定订阅输入框内容和打印内容，并通过takeUntil来解除绑定
    
    let vc = UIViewController()
    let textField = UITextField()
    
    /// 界面加载完成
    func viewDidLoad() {
        /// vc.rx.deallocated 当vc.dealloc被执行时，解除绑定
        _ = textField.rx.text.orEmpty
            .takeUntil(vc.rx.deallocated)
            .subscribe(onNext: { text in print(text) })
    }
    
    /// rx.deallocated本质是被绑定在NSObject的DeallocObservable对象，在deinit时，执行了event onNext和completed
}
