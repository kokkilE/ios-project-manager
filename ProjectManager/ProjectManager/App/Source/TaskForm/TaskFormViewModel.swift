//
//  TaskFormViewModel.swift
//  ProjectManager
//
//  Created by Harry, KokkiLE on 2023/05/22.
//

import Foundation
import Combine

final class TaskFormViewModel {
    private let projectManagerService = ProjectManagerService.shared
    private var task: MyTask?
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var isEditable: Bool
    @Published var isDone = false
    @Published var title: String = ""
    @Published var body: String = ""
    
    var deadline: TimeInterval {
        return task?.deadline ?? Date().timeIntervalSince1970
    }
    
    var leftBarButtonTitle: String {
        return task != nil ? "Edit" : "Cancel"
    }
    
    var rightBarButtonTitle: String {
        return "Done"
    }
    
    var navigationTitle: String? {
        return task != nil ? task?.state.description : TaskState.todo.description
    }
    
    init(task: MyTask? = nil) {
        self.task = task
        isEditable = (task == nil)
        
        title = task?.title ?? ""
        body = task?.body ?? ""
        
        assignToIsDone()
    }

    func isNetworkConnectedPublisher() -> AnyPublisher<Bool, Never> {
        return projectManagerService.isNetworkConnectedPublisher()
    }
    
    func cancelOrEditAction(action: (() -> Void)?) {
        if task == nil {
            action?()
            
            return
        }
        
        isEditable = true
    }
    
    func doneAction(title: String, date: TimeInterval, body: String) {
        if task != nil {
            updateTask(title: title, date: date, body: body)
            
            return
        }
        
        addTask(title: title, date: date, body: body)
    }
    
    private func assignToIsDone() {
        Publishers
            .CombineLatest($title, $body)
            .map { (title, body) in
                !title.isEmpty && !body.isEmpty
            }
            .assign(to: \.isDone, on: self)
            .store(in: &subscriptions)
    }
    
    private func addTask(title: String, date: TimeInterval, body: String) {
        let task = MyTask(state: .todo, title: title, body: body, deadline: date)
        
        projectManagerService.create(task)
    }
    
    private func updateTask(title: String, date: TimeInterval, body: String) {
        task?.title = title
        task?.deadline = date
        task?.body = body
        
        guard let task else { return }
        
        projectManagerService.update(task)
    }
}
