//
//  Temp.swift
//  Learning RxSwift
//
//  Created by 刘嘉豪 on 2020/10/14.
//  Copyright © 2020 刘嘉豪. All rights reserved.
//

import Foundation
import RxSwift

var disposeBag = DisposeBag()

var url: URL! = URL(string: "https://www.baidu.com")!

func waitRequestCompletedForTest() { sleep(3) }

extension String: Error {}
