//
//  Observer.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/14.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Observer

func testObserver() {
    /// 获取按钮的tap序列
    let tap = UIButton().rx.tap
    /// 订阅按钮的tap序列
    tap.subscribe(onNext: { (_) in
        print("taped")
    }, onError: { (error) in
        print(error)
    }, onCompleted: {
        print("completed")
    }, onDisposed: {
        print("disposed")
    }).disposed(by: disposeBag)
}

// MARK: AnyObserver

func testAnyObserver() {
    /// 描述任意观察者
    URLSession.shared.rx.data(request: URLRequest(url: url)).subscribe(onNext: { (data) in
        print("request data: \(data.count)")
    }, onError: { (error) in
        print("request error: \(error)")
    }, onCompleted: {
        print("request completed")
    }, onDisposed: {
        print("request disposed")
    }).disposed(by: disposeBag)
    
    /// ⬆️⬇️等价
    
    let observer: AnyObserver<Data> = AnyObserver { (event) in
        switch event {
            case .next(let data):
            print("request data: \(data.count)")
            case .error(let error):
            print("request error: \(error)")
            case .completed:
            print("request completed")
        }
    }
        
    URLSession.shared.rx.data(request: URLRequest(url: url))
        .subscribe(observer)
        .disposed(by: disposeBag)
    
    waitRequestCompletedForTest()
}

// MARK: Binder

func testBinder() {
    
    let usernameTextField = UITextField()
    
    let usernameValid: Observable<Bool> = Observable.create { (ob) -> Disposable in
        ob.onNext(true)
        ob.onNext(false)
        return Disposables.create()
    }
    
    let observer: AnyObserver<Bool> = AnyObserver { (event) in
        switch event {
        case .next(let isHidden):
            usernameTextField.isHidden = isHidden
        default:
            break
        }
    }

    usernameValid
        .bind(to: observer)
        .disposed(by: disposeBag)
    
    /// 由于这个观察者是一个 UI 观察者，所以它在响应事件时，只会处理 next 事件，并且更新 UI 的操作需要在主线程上执行。
    /// 所以有个更好的方案就是Binder
    
    /**
    1、无法处理错误
    2、确保绑定都是在给定 Scheduler 上执行（默认 MainScheduler）
    一旦产生错误事件，在调试环境下将执行 fatalError，在发布环境下将打印错误信息。
    */
    
    let binder: Binder<Bool> = Binder(usernameTextField, scheduler: MainScheduler.instance) { (view, isHidden) in
        view.isHidden = isHidden
    }
    
    usernameValid
        .bind(to: binder)
        .disposed(by: disposeBag)
    
    /// 因为是否隐藏是UIView的通用属性，所以应该让所有的view都能提供这种观察者
    usernameValid
        .bind(to: usernameTextField.rx.isHidden)
        .disposed(by: disposeBag)
    
    /// 还有些比如：UIControl.rx.isEnable, UILabel.rx.text 等等。。
}
