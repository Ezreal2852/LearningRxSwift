//
//  Schedulers.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/25.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Schedulers

func testSchedulers() {
    
    /**
     subscribeOn：决定数据序列的构建函数在哪个Scheduler中执行
     observeOn：决定在哪个Scheduler监听数据序列
     */
    
    let rxString: Observable<String> = Observable.create { (ob) -> Disposable in
        print("waiting... at a global queue", Thread.current)
        sleep(3)
        ob.onNext("after 3s...")
        return Disposables.create()
    }
    
    rxString
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (str) in
            print("handle \(str) in main queue", Thread.current)
        })
        .disposed(by: disposeBag)
    
    sleep(4)
    
    /// 主线程
    _ = MainScheduler.instance
    /// 串行队列
    _ = SerialDispatchQueueScheduler(qos: .userInitiated)
    /// 并行队列
    _ = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    /// OperationQueue，support maxConcurrentOperationCount
    let opQueue = OperationQueue()
    opQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    _ = OperationQueueScheduler(operationQueue: opQueue)
}
