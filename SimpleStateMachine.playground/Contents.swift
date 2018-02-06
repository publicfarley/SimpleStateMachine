precedencegroup ForwardApplication { // Nomencalture as per pointfree.co (https://www.pointfree.co/episodes/ep1-functions)
    associativity: left
}

infix operator |> : ForwardApplication

func |> <T,U>(lhs: T, rhs: (T) -> U) -> U {
    return rhs(lhs)
}

func composeOrdered<A,B,C>(_ f: @escaping (A) -> B, then g: @escaping (B) -> C)
    -> (A) -> C {
        
        return { a in g(f(a)) }
}

// Forward Compose infix opperator (mimics F# operator)
precedencegroup ForwardComposition { // Nomencalture as per pointfree.co (https://www.pointfree.co/episodes/ep1-functions)
    associativity: left
    higherThan: ForwardApplication
}

infix operator >> : ForwardComposition

func >> <A,B,C>(lhs: @escaping (A) -> B, rhs: @escaping (B) -> C) -> (A) -> C {
    return composeOrdered(lhs, then: rhs)
}

// ---------------------------------------------------------
typealias Code = String
typealias Repo = Array<Code>

struct Developer {
    
    enum Command {
        case drinkCoffee
        case writeCode
    }
    
    enum State {
        case fueld(Code)
        case empty
    }

    var repo: Repo
    
    var state: State {
        didSet {
            switch state {
                
            case .fueld(let code):
                repo.append(code)
                
            case .empty:
                break
            }
        }
    }
}

extension Developer {
    
    func handle(command: Developer.Command) -> Developer {
        
        switch (self.state, command) {
            
        case (.empty, .drinkCoffee):
            
            let code = "let add1: (Int) -> Int = { $0 + 1 }"
            var developer = Developer(repo: self.repo, state: self.state)
            developer.state = .fueld(code)
            
            return developer
            
        case (.fueld, .drinkCoffee):
            fatalError() // TODO: Can we handle this at compile time??
            
        case (.empty, .writeCode):
            fatalError() // TODO: Can we handle this at compile time??
            
        case (.fueld, .writeCode):
            return Developer(repo: self.repo, state: .empty)
        }
    }
}



// Side effecting method to handle data embedded in particular state
func doRender(_ developer: Developer) -> Void {
    print("Got some code from a developer: \n > \(developer.repo)")
}

Developer(repo: [], state: .empty)
    .handle(command: .drinkCoffee)
    .handle(command: .writeCode)
    .handle(command: .drinkCoffee)
    .handle(command: .writeCode)
    |> doRender


let add1ThenAdd2 = { (x: Int) -> Int in x + 1 } >> { (x: Int) -> Int in x + 2 }

print("\n---------------\n")

Developer(repo: [], state: .empty) |> { (dev: Developer) -> Developer in dev.handle(command: .drinkCoffee) } |> doRender

let commander: (Developer) -> (Developer.Command) -> Developer = {
    (dev: Developer) in
        return { (command: Developer.Command) in
            return dev.handle(command: command)
    }
}

((Developer(repo: [], state: .empty) |> commander)(.drinkCoffee) |> commander)(.writeCode)

Developer(repo: [], state: .empty)
    |> { $0.handle(command: .drinkCoffee) }
    |> doRender

protocol Empty {}; protocol Fueld {}
struct AnnotatedDeveloper<T> {
    let developer: Developer
    
    static func drinkCoffee(_ emptyDeveloper: AnnotatedDeveloper<Empty>) -> AnnotatedDeveloper<Fueld> {
        let code = "let add1: (Int) -> Int = { $0 + 1 }"
        var developer = emptyDeveloper.developer
        developer.state = .fueld(code)
        
        return AnnotatedDeveloper<Fueld>(developer: developer)
    }
    
    static func writeCode(_ fueldDeveloper: AnnotatedDeveloper<Fueld>) -> AnnotatedDeveloper<Empty> {
        var developer = fueldDeveloper.developer
        developer.state = .empty
        
        return AnnotatedDeveloper<Empty>(developer: developer)
    }

}

AnnotatedDeveloper<Empty>.drinkCoffee(AnnotatedDeveloper<Empty>(developer: Developer(repo: [], state: .empty)))

print("\n---------------\n")

AnnotatedDeveloper<Empty>(developer: Developer(repo: [], state: .empty))
    |> AnnotatedDeveloper<Empty>.drinkCoffee
    >> AnnotatedDeveloper<Fueld>.writeCode
    >> AnnotatedDeveloper<Empty>.drinkCoffee
    >> AnnotatedDeveloper<Fueld>.writeCode
    |> { doRender($0.developer) }

struct Thing<T> {}
protocol Cool {}; protocol Hot {}

func turnCoolThingHot(_ thing: Thing<Cool>) -> Thing<Hot> {
    return Thing<Hot>()
}

let hotThing = Thing<Hot>()
// turnCoolThingHot(hotThing) -- Compiler error. Illegal operation.

let coolThing = Thing<Cool>()
let thing = turnCoolThingHot(coolThing) // 👍

print(type(of: thing))




