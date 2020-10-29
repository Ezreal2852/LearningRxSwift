//
//  Observable&Observer.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Observable & Observer

func testObservaleAndObserver() {
    /// 既是可监听的序列，也是观察者
    /// 例如：textField的当前文本。它可以看成是由用户输入，而产生的一个文本序列。也可以是由外部文本序列，来控制当前显示内容的观察者
    
    let textField = UITextField()
    
    /// 作为一个可监听的序列
    let observable = textField.rx.text
    
    observable.subscribe(onNext: { (text) in
        print("textField.text: \(text ?? "")")
    }).disposed(by: disposeBag)
    
    /// 作为观察者
    let observer = textField.rx.text
    
    let text: Observable<String?> = Observable.create { (ob) -> Disposable in
        ob.onNext("input a text")
        return Disposables.create()
    }
    
    text.bind(to: observer).disposed(by: disposeBag)
    
    /// 还有很多UI控件都有这样的特性，具有读写的属性，譬如UISwitch的开关状态
}

// MARK: AsyncSubject

func testAsyncSubject() {
    /**
     AsyncSubject 将在源 Observable 产生完成事件后，发出最后一个元素（仅仅只有最后一个元素），
     如果源 Observable 没有发出任何元素，只有一个完成事件。
     那 AsyncSubject 也只有一个完成事件。
     它会对随后的观察者发出最终元素。如果源 Observable 因为产生了一个 error 事件而中止，
     AsyncSubject 就不会发出任何元素，而是将这个 error 事件发送出来。
     */
    let subject = AsyncSubject<String>()
    
    subject
        .subscribe { print("Subscription1 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🐶")
    subject.onNext("🐱")
    subject.onNext("🐹")
    // 如果产生错误，则不会发送元素，也不会完成，而是直接error
//    subject.onError("❌")
    subject.onCompleted()
    
    /// 适用场景：发送者和监听者为同一个对象，且我只关注最后一个元素
}

// MARK: PublishSubject

func testPublishSubject() {
    /**
     PublishSubject 将对观察者发送订阅后产生的元素，而在订阅前发出的元素将不会发送给观察者。
     如果你希望观察者接收到所有的元素，你可以通过使用 Observable 的 create 方法来创建 Observable，或者使用 ReplaySubject。
     如果源 Observable 因为产生了一个 error 事件而中止， PublishSubject 就不会发出任何元素，而是将这个 error 事件发送出来。
     */
    let subject = PublishSubject<String>()
    
    subject
        .subscribe { print("Subscription: 1 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🐶")
    subject.onNext("🐱")
    
    subject
        .subscribe { print("Subscription: 2 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🅰️")
//    subject.onCompleted()
//    subject.onError("❌")
    subject.onNext("🅱️")
    
    /// 适用场景：发送者和监听者为同一个对象，向当前已订阅发送全部元素，发送之后订阅的不会收到订阅前发送的
}
    
// MARK: ReplaySubject

func testReplaySubject() {
    /**
     ReplaySubject 将对观察者发送全部的元素，无论观察者是何时进行订阅的。
     这里存在多个版本的 ReplaySubject，有的只会将最新的 n 个元素发送给观察者，有的只会将限制时间段内最新的元素发送给观察者。
     如果把 ReplaySubject 当作观察者来使用，注意不要在多个线程调用 onNext, onError 或 onCompleted。这样会导致无序调用，将造成意想不到的结果。
     */
    let subject = ReplaySubject<String>.create(bufferSize: 1)
    
    subject
        .subscribe { print("Subscription: 1 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🐶")
    subject.onNext("🐱")
    
    subject
        .subscribe { print("Subscription: 2 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🅰️")
    subject.onNext("🅱️")
    
    /// 适用场景：发送者和监听者为同一个对象，向当前已订阅发送全部元素，并向之后订阅者发送订阅前发送最近的bufferSize个元素
}

// MARK: BehaviorSubject

func testBehaviorSubject() {
    /**
     当观察者对 BehaviorSubject 进行订阅时，它会将源 Observable 中最新的元素发送出来（如果不存在最新的元素，就发出默认元素）。
     然后将随后产生的元素发送出来。
     如果源 Observable 因为产生了一个 error 事件而中止， BehaviorSubject 就不会发出任何元素，而是将这个 error 事件发送出来。
     */

    let subject = BehaviorSubject(value: "🔴")
    
    subject
        .subscribe { print("Subscription: 1 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🐶")
    subject.onNext("🐱")
    
    subject
        .subscribe { print("Subscription: 2 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🅰️")
    subject.onNext("🅱️")
    
    subject
        .subscribe { print("Subscription: 3 Event:", $0) }
        .disposed(by: disposeBag)
    
    subject.onNext("🍐")
    subject.onNext("🍊")
    
    /// 相当于比PublishSubject多了一个默认值，最初用BehaviorSubject初始化的value，而后订阅的默认值为订阅前发送的最后一个元素
}

// MARK: ControlProperty

func testControlProperty() {
    /**
     ControlProperty 专门用于描述 UI 控件属性的，它具有以下特征：
     不会产生 error 事件
     一定在 MainScheduler 订阅（主线程订阅）
     一定在 MainScheduler 监听（主线程监听）
     共享附加作用
     */
    let text: ControlProperty<String?> = UITextField().rx.text
    let _: ControlProperty<Bool> = UISwitch().rx.isOn
    let _: ControlProperty<Float> = UISlider().rx.value
        
    /// 发送UITextField的text发生变化的元素
    text.onNext("set text")
    /// 订阅UITextField的text改变，会获取一次当前值，然后每次发生变更才触发
    /// 为什么会获取一次当前值呢？因为subscribe调用中创建observer时执行了一次Event.onNext(当前值)
    text.subscribe(onNext: { print("get text: \($0 ?? "nil")") }).disposed(by: disposeBag)
    /// 不会触发上面订阅的事件
    text.onNext("set new text")
        
    // UI控件属性，这个属性，可以被外部设置修改，也可以自身修改本属性，
    // 如果只能被外部设置，而自身无法改变的属性，用Binder
}
