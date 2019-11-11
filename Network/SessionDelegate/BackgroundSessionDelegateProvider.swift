import Foundation

open class BackgroundSessionDelegateProvider: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {

    public var backgroundCompletionHandler: (() -> Void)?

    public var dataTaskDataHolder: [Int: NetworkLayer.SessionTaskData] = [:]
    public var downloadTaskDataHolder: [Int: NetworkLayer.SessionDownloadTaskData] = [:]

    open init() {}

    // MARK: - Task management

    open func addDataTaskData(_ data: NetworkLayer.SessionTaskData) {
        dataTaskDataHolder[data.task.taskIdentifier] = data
    }

    open func addDownloadTaskData(_ data: NetworkLayer.SessionDownloadTaskData) {
        downloadTaskDataHolder[data.task.taskIdentifier] = data
    }

    // MARK: - URLSessionDelegate

    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        debugPrint("URLSession(\(session.sessionDescription ?? "unnamed")):didBecomeInvalidWithError:\(error ?? NetworkError.unexpected)")
    }

    open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let backgroundHandler = backgroundCompletionHandler
        backgroundCompletionHandler = nil

        DispatchQueue.main.async {
            backgroundHandler?()
        }
    }

    // MARK: - URLSessionTaskDelegate

    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let data = dataTaskDataHolder.first(where: { $0.key == task.taskIdentifier })?.value {
            dataTaskDataHolder[task.taskIdentifier] = nil
            data.completionHandler?(nil, task.response, error)
        } else if let data = downloadTaskDataHolder.first(where: { $0.key == task.taskIdentifier })?.value {
            downloadTaskDataHolder[task.taskIdentifier] = nil
            data.completionHandler?(nil, task.response, error)
        }
    }

    // MARK: - URLSessionDataDelegate

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let taskData = dataTaskDataHolder.first(where: { $0.key == dataTask.taskIdentifier })?.value {
            dataTaskDataHolder[dataTask.taskIdentifier] = nil
            taskData.completionHandler?(data, dataTask.response, nil)
        }
    }

    // MARK: - URLSessionDownloadDelegate

    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let taskData = downloadTaskDataHolder.first(where: { $0.key == downloadTask.taskIdentifier })?.value {
            downloadTaskDataHolder[downloadTask.taskIdentifier] = nil
            taskData.completionHandler?(location, downloadTask.response, nil)
        }
    }

}
