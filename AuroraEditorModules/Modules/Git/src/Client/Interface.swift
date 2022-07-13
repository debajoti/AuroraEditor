//
//  Interface.swift
//  CodeEditModules/Git
//
//  Created by Marco Carnevali on 21/03/22.
//
import Foundation
import Combine

// TODO: DOCS (Marco Carnevali)
// swiftlint:disable missing_docs

public struct GitClient {
    public var getCurrentBranchName: () throws -> String
    public var getBranches: (Bool) throws -> [String]
    public var checkoutBranch: (String) throws -> Void
    public var pull: () throws -> Void
    public var cloneRepository: (String) -> AnyPublisher<CloneProgressResult, GitClientError>
    /// Displays paths that have differences between the index file and the current HEAD commit,
    /// paths that have differences between the working tree and the index file, and paths in the working tree
    public var getChangedFiles: () throws -> [ChangedFile]
    /// Get commit history
    /// - Parameters:
    ///   - entries: number of commits we want to fetch. Will use max if nil
    ///   - fileLocalPath: specify a local file (e.g. `CodeEditModules/Package.swift`)
    ///   to retrieve a file commit history. Optional.
    public var getCommitHistory: (_ entries: Int?, _ fileLocalPath: String?) throws -> [Commit]
    public var discardFileChanges: (String) throws -> Void
    public var discardProjectChanges: () throws -> Void

    init(
        getCurrentBranchName: @escaping () throws -> String,
        getBranches: @escaping (Bool) throws -> [String],
        checkoutBranch: @escaping (String) throws -> Void,
        pull: @escaping () throws -> Void,
        cloneRepository: @escaping (String) -> AnyPublisher<CloneProgressResult, GitClientError>,
        getChangedFiles: @escaping () throws -> [ChangedFile],
        getCommitHistory: @escaping (_ entries: Int?, _ fileLocalPath: String?) throws -> [Commit],
        discardFileChanges: @escaping (String) throws -> Void,
        discardProjectChanges: @escaping () throws -> Void
    ) {
        self.getCurrentBranchName = getCurrentBranchName
        self.getBranches = getBranches
        self.checkoutBranch = checkoutBranch
        self.pull = pull
        self.cloneRepository = cloneRepository
        self.getChangedFiles = getChangedFiles
        self.getCommitHistory = getCommitHistory
        self.discardFileChanges = discardFileChanges
        self.discardProjectChanges = discardProjectChanges
    }

    public enum GitClientError: Error {
        case BadConfigFile
        case AuthenticationFailed
        case NoUserNameConfigured
        case NoUserEmailConfigured
        case NotAGitRepository
        case NotAtRepositoryRoot
        case Conflict
        case StashConflict
        case UnmergedChanges
        case PushRejected
        case RemoteConnectionError
        case DirtyWorkTree
        case CantOpenResource
        case GitNotFound
        case CantCreatePipe
        case CantAccessRemote
        case RepositoryNotFound
        case RepositoryIsLocked
        case BranchNotFullyMerged
        case NoRemoteReference
        case InvalidBranchName
        case BranchAlreadyExists
        case NoLocalChanges
        case NoStashFound
        case LocalChangesOverwritten
        case NoUpstreamBranch
        case IsInSubModule
        case WrongCase
        case CantLockRef
        case CantRebaseMultipleBranches
        case PatchDoesNotApply
        case outputError(String)
        case notGitRepository
        case failedToDecodeURL
    }

    public enum CloneProgressResult {
        case receivingProgress(Int)
        case resolvingProgress(Int)
        case other(String)
    }
}