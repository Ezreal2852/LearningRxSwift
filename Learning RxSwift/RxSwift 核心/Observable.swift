//
//  Observable.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/9.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

// MARK: - Observable

func testObservable() {
    /// 创建一个可监听的序列
    let numbers: Observable<Int> = Observable.create { (observer) -> Disposable in
        /// next - 序列产生了一个新的元素
        observer.onNext(0)
        observer.onNext(1)
        /// error - 创建序列时产生了一个错误，导致序列终止
//        observer.onError("error")
        observer.onNext(2)
        /// completed - 序列的所有元素都已经成功产生，整个序列已经完成
        observer.onCompleted()
        return Disposables.create {
            /// 如果数据绑定被清除，执行清理操作，比如网络请求取消 task.cancel()
            /// 如果什么都不做，可以用Disposables.create()
        }
    }
    
    /// 订阅可监听的序列
    numbers.subscribe { (event) in
        /// 处理序列发送的事件
        switch event {
            case .next(let num): print(num)
            case .error(let error): print(error)
            case .completed: print("completed")
        }
    }.disposed(by: disposeBag)
}

// MARK: Single

func testSingle() {
    /// 只能发出一个元素，要么产生一个 error 事件，不会共享附加作用。
    /// 譬如：一个Http请求，只有成功或者失败一种结果
    let single: Single<Int> = Single.create { (single) -> Disposable in
        /// 只会执行第一个SingleEvent，其他无效
        single(.success(0))
        single(.success(1))
        single(.error("single error"))
        return Disposables.create()
    }
    /// 可以对 Observable 调用 .asSingle() 方法，将它转换为 Single。
    single.subscribe { (event) in
        switch event {
            case .success(let ele): print("single success: \(ele)")
            case .error(let err): print("single error: \(err)")
        }
    }.disposed(by: disposeBag)
}

// MARK: Completable

func testCompletable() {
    /// 要么只能产生一个 completed 事件，要么产生一个 error 事件。
    /// Completable 适用于那种你只关心任务是否完成，而不需要在意任务返回值的情况。它和 Observable<Void> 有点相似。
    let completable = Completable.create { (observer) -> Disposable in
        observer(.completed)
        observer(.error("completable error"))
        return Disposables.create()
    }
    
    completable.subscribe { (event) in
        switch event {
            case .completed: print("completable completed")
            case .error(let err): print(err)
        }
    }.disposed(by: disposeBag)
}

// MARK: Maybe

func testMaybe() {
    /// 要么只能发出一个元素，要么产生一个 completed 事件，要么产生一个 error 事件。
    /// 如果你遇到那种可能需要发出一个元素，又可能不需要发出时，就可以使用 Maybe。
    let maybe = Maybe<Any>.create { (observer) -> Disposable in
        observer(.success("maybe success"))
        observer(.completed)
        observer(.error("maybe error"))
        return Disposables.create()
    }
    /// 可以对 Observable 调用 .asMaybe() 方法，将它转换为 Maybe。
    maybe.subscribe { (event) in
        switch event {
            case .success(let ele): print(ele)
            case .completed: print("maybe completed")
            case .error(let err): print(err)
        }
    }.disposed(by: disposeBag)
}

// MARK: Driver

func testDriver() {
    /// 不会产生error，一定在 MainScheduler 监听（主线程监听），共享附加作用。
    /// 都是驱动UI序列的特性
    
    /// 为什么用Driver？

    let queryTextField = UITextField()
    let resultCountLabel = UILabel()
    let resultsTableView = UITableView()
    
    /// 取出用户稳定输入后内容
    let results = queryTextField.rx.text
        .throttle(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
        .flatMapLatest { query in
            /// 向服务器请求一组结果
            fetchAutoCompleteItems(query)
        }

    /// 绑定显示结果的数目
    results
        .map { "\($0.count)" }
        .bind(to: resultCountLabel.rx.text)
        .disposed(by: disposeBag)

    /// 绑定显示结果的列表
    results
        .bind(to: resultsTableView.rx.items(cellIdentifier: "Cell")) {
          (_, result, cell) in
            cell.textLabel?.text = "\(result)"
        }
        .disposed(by: disposeBag)
    
    /// 返回的结果被绑定到两个 UI 元素上。那就意味着，每次用户输入一个新的关键字时，就会分别为两个 UI 元素发起 HTTP 请求。
    
    func fetchAutoCompleteItems(_ query: String?) -> Observable<[String]> {
        Observable<[String]>.create { (observer) -> Disposable in
            /// 如果 fetchAutoCompleteItems 的序列产生了一个错误（网络请求失败）
            /// 如果 fetchAutoCompleteItems 在后台返回序列，那么刷新页面也会在后台进行，这样就会出现异常崩溃。
            return Disposables.create {
                /// 这个错误将取消所有绑定，当用户输入一个新的关键字时，是无法发起新的网络请求。
            }
        }}
    
    /// 解决了上面三个问题的方案
    let newResults = queryTextField.rx.text
        .throttle(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
        .flatMapLatest { query in
            fetchAutoCompleteItems(query)
    }
    .observeOn(MainScheduler.instance)// 结果在主线程返回
    .catchErrorJustReturn([])// 处理了错误，序列不会终止
    .share(replay: 1)// 请求是被共享的
    
    newResults
        .map { "\($0.count)" }
        .bind(to: resultCountLabel.rx.text)
        .disposed(by: disposeBag)

    newResults
        .bind(to: resultsTableView.rx.items(cellIdentifier: "Cell")) {
          (_, result, cell) in
            cell.textLabel?.text = "\(result)"
        }
        .disposed(by: disposeBag)
    
    /// 但是，这样很麻烦！！！实际开发中，UI和网络交互非常常见，当然有更简单的方案，Driver！！！
    let bestResults = queryTextField.rx.text.asDriver()
        .throttle(RxTimeInterval.milliseconds(300))
        .flatMapLatest { query in
            fetchAutoCompleteItems(query)
                .asDriver(onErrorJustReturn: [])// 错误时，返回备选值[]
    }
    
    /// Driver的绑定不用bind to了，用dirve
    bestResults.map { "\($0.count)" }
        .drive(resultCountLabel.rx.text)
        .disposed(by: disposeBag)
    
    /// items(_, _) -> ()->()->()  是能够集中语法的关键点，返回值是一个三层嵌套的闭包
    bestResults.drive(resultsTableView.rx.items(cellIdentifier: "cell")) {
        (_, result, cell) in
        cell.textLabel?.text = result
    }.disposed(by: disposeBag)
    
    /// 任何Observable都可以转换成Driver，但需满足三个条件，不会error，在主线程监听，共享附加作用
    let safeSequence = queryTextField.rx.text
        .observeOn(MainScheduler.instance)
        .share(replay: 1, scope: .whileConnected)
    let driver = safeSequence.asDriver(onErrorJustReturn: "")
    print(driver)
}

// MARK: Signal

func testSignal() {
    /// Signal 和 Driver 相似，唯一的区别是，Driver 会对新观察者回放（重新发送）上一个元素，而 Signal 不会对新观察者回放上一个元素。
    
    /// 例子：“将用户输入的姓名绑定到对应的标签上。当用户输入姓名后，我们创建了一个新的观察者，用于订阅姓名的字数。
    /// 那么问题来了，订阅时，展示字数的标签会立即更新吗？
    
    let textField = UITextField()
    let nameLabel = UILabel()
    let nameSizeLabel = UILabel()
    
    let state: Driver<String?> = textField.rx.text.asDriver()
    let observer = nameLabel.rx.text
    
    state.drive(observer).disposed(by: disposeBag)
    
    /// 。。。假设以下代码是在用户输入姓名后运行
    
    let newOberver = nameSizeLabel.rx.text
    
    /// nameSizeLabel会更新，因为Driver会对新观察者回放上一个元素，也就是当前的名字
    
    state.map {
        $0?.count.description
    }
    .drive(newOberver)
    .disposed(by: disposeBag)
    
    /// 例子：点击按钮弹出提示框
    
    let button = UIButton()
    let showAlert: ((String) -> Void) = { print($0) }
    
    let event: Driver<Void> = button.rx.tap.asDriver()
    
    let alertObserver: (() -> Void) = {
        showAlert("弹出提示框1")
    }
    event.drive(onNext: alertObserver).disposed(by: disposeBag)
    
    /// 假设以下代码在button点击后运行
    
    let newAlertObserver: (() -> Void) = {
        showAlert("弹出提示框2")
    }
    event.drive(onNext: newAlertObserver).disposed(by: disposeBag)
    
    /// 此时，弹出提示框2也会被执行，这种情况下，就不太合理
    
    /// 于是，就有了Signal：信号。
    let signal: Signal<Void> = button.rx.tap.asSignal()
    
    let signalObserver: (() -> Void) = {
        showAlert("弹出提示框1")
    }
    signal.emit(onNext: signalObserver).disposed(by: disposeBag)
    
    /// 假设以下代码在button点击后运行
    
    let newSignalObserver: (() -> Void) = {
        showAlert("弹出提示框2")
    }
    signal.emit(onNext: newSignalObserver).disposed(by: disposeBag)
    
    /// Signal 不会把上一次的点击事件回放给新的观察者，所以弹出提示框2不会执行
    
    /// 结论：一般情况下状态序列我们会选用 Driver 这个类型，事件序列我们会选用 Signal 这个类型。
}

// MARK: Control Event

func testControlEvent() {
    let button = UIButton()
    let _: ControlEvent<Void> = button.rx.tap
    
    /// 专门用于UI控件产生的事件
    /// 不会产生error
    /// 一定在主线程中订阅
    /// 一定在主线程中监听
    /// 共享附加作用
}

// MARK: Adjection

func testAdjection() {
    /// 何为共享附加作用？
    /// 先了解下何为 附加作用吧！
    
    /// 函数的附加作用：如果一个函数除了计算返回值以外，还有其他可观测作用（例如为了获取返回值需要获取值或者返回之前写入值），这个函数拥有附加作用。
    /// 网络请求：如果一个函数发起网络请求，为了获取结果，可能需要用到全局的参数，或者返回结果之前缓存数据，这些都是附加作用；
    /// 获取位置：。。。
    /// 获取UI状态：。。。等
    /// 常见的函数附加作用：读写全局变量、读写本地数据库、读写文件、使用蓝牙、打印日志、埋点等
    
    /// APP的附加作用
    /// 美团：是一个订餐APP，主要附加作用是让我们从 饿->饱
    /// B站：。。。
    /// 滴滴：。。。等
    
    /// 扯远了
    
    /// Observable中的附加作用
    /// 去掉泛型约束后，这就是ObservableType协议中唯一功能函数
    /// func subscribe(_ observer: Observer) -> Disposable
    /// 换言之，Observable的附加作用，就是subscribe函数的附加作用
    
    /// 一个网络请求的例子：通过网络请求获取一个json数据
    typealias JSON = Any
    
    let json: Observable<JSON> = Observable.create { (observer) -> Disposable in
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                observer.onError(error!)
                return
            }
            
            guard let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) else {
                    observer.onError("DataError.cantParseJSON")
                    return
            }
            
            observer.onNext(jsonObject)
            observer.onCompleted()
        }
        
        task.resume()
        
        return Disposables.create { task.cancel() }
    }
    /// 为Observable设置共享附加
//    .share(replay: 1, scope: .whileConnected)
    
    json.subscribe(onNext: { (json) in
        print(json)
    }, onError: { (error) in
        print(error)
    }, onCompleted: {
        print("completed")
    }, onDisposed: {
        /// handle disposed
    }).disposed(by: disposeBag)
    
    /// Observable.create的返回值，就是Observable，这个 { (observer) -> Disposable in ... }  函数可以看作是subscribe，里面执行的代码就是这个函数的附加作用
    /// 所以，json: Observable<JSON>的附加作用就是网络请求获取一个json数据
    
    /// 终于回到正题！何为共享附加作用？
    
    let sharedJson = json.asDriver(onErrorJustReturn: "")
    let notSharedJson = json.asSingle()
    
    /// 共享附加作用的Observable在订阅时不会重新发送网络请求
    sharedJson.drive(onNext: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    /// 非共享附加作用的Observable在订阅时重新发送网络请求
    notSharedJson.subscribe(onSuccess: nil, onError: nil).disposed(by: disposeBag)
}


