//
//  Error Handling.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Error Handling

/**
 一旦序列发生了一个error事件，整个序列将会被终止。RxSwift主要有两种错误处理机制：
 retry：重试
 catch：恢复
 */

// MARK: retry

func testRetry() {
    /// 失败后立即进行重试
    /// retry(最多失败的次数，达到次数后，就报错)
    let retryCount: Int = 3
    var currentTime: Int = 0
    
    let rxJson: Observable<Any> = Observable.create { (ob) -> Disposable in
        currentTime += 1
        print("error time = \(currentTime)")
        ob.onError("onError time = \(currentTime)")
        return Disposables.create()
    }
    
    /// 如果是retry()，那么将重试无限次，直至成功
    
    rxJson
        .retry(retryCount)
        .debug()
        .subscribe(onNext: { (json) in
            print(json)
        }, onError: { (error) in
            print(error)
        })
        .disposed(by: disposeBag)
}

// MARK: retryWhen

func testRetryWhen() {
    /// 失败后，进过一段时间进行重试
    
    /// 重试延迟
    let retryDelay: RxTimeInterval = RxTimeInterval.seconds(3)
    /// 最大重试次数
    let retryMaxCount: Int = 3
    
    let rxJson: Observable<Any> = Observable.create { (ob) -> Disposable in
        print("send error")
        ob.onError("error")
        return Disposables.create()
    }
    
    rxJson.retryWhen { (rxError) -> Observable<Int> in
        return rxError.enumerated().flatMap { (index, error) -> Observable<Int> in
            print(index, error)
            guard index < retryMaxCount else { return Observable.error(error) }
            return Observable.timer(retryDelay, scheduler: MainScheduler.instance)
        }
    }.subscribe(onNext: { (json) in
        print(json)
    }, onError: { (error) in
        print("onError: \(error)")
    }).disposed(by: disposeBag)
}

// MARK: catchError

func testCatchError() {
    /// 捕获错误，通过一个或一组元素来替换错误
    let rxJson: Observable<Any> = Observable.create { (ob) -> Disposable in
        print("send error")
        ob.onError("error")
        return Disposables.create()
    }
    
    /// 手动进行处理，可以自定义操作error，提示or埋点
    rxJson.catchError { (error) -> Observable<Any> in
        return Observable.create { (ob) -> Disposable in
            print("catch \(error)")
            ob.onNext("catch empty")
            return Disposables.create()
        }
    }.subscribe(onNext: { (json) in
        print(json)
    }, onError: { (error) in
        print(error)
    }, onCompleted: {
        print("onCompleted")
    }, onDisposed: {
        print("disposed")
    }).disposed(by: disposeBag)
    
    /// 替换error后，自动onCompleted和onDisposed
    rxJson.catchErrorJustReturn("just empty")
        .subscribe(onNext: { (json) in
            print(json)
        }, onError: { (error) in
            print(error)
        }, onCompleted: {
            print("onCompleted")
        }, onDisposed: {
            print("disposed")
        }).disposed(by: disposeBag)
}

// MARK: result

func testResult() {
    
    /// 如果一个序列出现error，然后通过catchErrorJustReturn处理了error
    /// 序列会终止并解除绑定，如果仅希望提示用户错误，就无法达到
    
    /// 虽然目前将error，转换成了Result.failure，但是仍然会执行complete, dispose
    /// 有问题
    
    let rxJson: Observable<Any> = Observable.create { (ob) -> Disposable in
        ob.onNext("success")
        ob.onError("error")
        return Disposables.create()
    }
    
    let rxObservale = Observable.just(rxJson)
    
    let rxResult = rxObservale.flatMapLatest { (ob) -> Observable<Result<Any, Error>> in
        return ob.map { Result.success($0) }
            .catchError { Observable.just(Result.failure($0)) }
    }
    
    rxResult
        .subscribe(onNext: { (result) in
            switch result {
                case .success(let json): print(json)
                case .failure(let error): print(error)
            }
        }, onError: { (error) in
            print("onError: \(error)")
        }, onCompleted: {
            print("onCompleted")
        }, onDisposed: {
            print("onDisposed")
        })
        .disposed(by: disposeBag)
}
