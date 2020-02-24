import XCTest
@testable import CodableFileBuffer

@available(iOS 13.0, *)
final class CodableFileBufferTests: XCTestCase {
    func test_canCreateBufferWithDesiredFilename() {
        // when
        let recorder = CodableFileBuffer<Person>()

        // then
        XCTAssertNotNil(recorder)
    }

    func test_countAfterRecordingTwo() {
        // given
        let persons = [
            Person(name: "Oliver"),
            Person(name: "Maike")
        ]
        let buffer = CodableFileBuffer<Person>()

        // when
        persons.forEach {
            buffer.append($0)
        }

        // then
        XCTAssert(buffer.count == 2)
    }

//    func test_append40_000Codables() {
//        // given
//        let buffer = CodableFileBuffer<Person>()
//
//        // when
//        for number in 1...40_000 {
//            buffer.append(Person(name: String(number)))
//        }
//
//        // then
//        XCTAssert(buffer.count == 40_000)
//    }

    func test_retrieve100Codables() {
        // given
        let buffer = CodableFileBuffer<Person>()
        for number in 1...5 {
            buffer.append(Person(name: String(number)))
        }

        // when
        let persons = buffer.retrieve()

        // then
        XCTAssert(persons.count == 5)
    }

    func test_resetBuffer() {
        // given
        let buffer = CodableFileBuffer<Person>()
        for number in 1...5 {
            buffer.append(Person(name: String(number)))
        }

        // when
        buffer.reset()
        buffer.append(Person(name: "Oliver"))
        let person = buffer.retrieve().first

        // then
        XCTAssert(person?.name == "Oliver")
    }
}

struct MyCodable: Codable {
    var id: Int
    var key: String
}

