import XCTest
@testable import CodableFileBuffer


final class CodableFileBufferTests: XCTestCase {
    func test_canCreateBufferWithDesiredFilename() {
        // when
        let recorder = try? CodableFileBuffer<Person>()

        // then
        XCTAssertNotNil(recorder)
    }

    func test_countAfterRecordingTwo() {
        // given
        let persons = [
            Person(name: "Oliver"),
            Person(name: "Maike")
        ]
        let buffer = try? CodableFileBuffer<Person>()

        // when
        persons.forEach {
            try? buffer?.append($0)
        }

        // then
        XCTAssert(buffer?.count == 2)
    }

    func test_append40_000Codables() {
        // given
        let buffer = try? CodableFileBuffer<Person>()

        // when
        for number in 1...40_000 {
            try? buffer?.append(Person(name: String(number)))
        }

        // then
        XCTAssert(buffer?.count == 40_000)
    }

    func test_retrieve100Codables() {
        // given
        let buffer = try? CodableFileBuffer<Person>()
        for number in 1...5 {
            try? buffer?.append(Person(name: String(number)))
        }

        // when
        let persons = buffer?.retrieve()

        // then
        XCTAssert(persons?.count == 5)
    }

    func test_resetBuffer() {
        // given
        let buffer = try? CodableFileBuffer<Person>()
        for number in 1...5 {
            try? buffer?.append(Person(name: String(number)))
        }

        // when
        try? buffer?.reset()
        try? buffer?.append(Person(name: "Oliver"))
        let person = buffer?.retrieve().first

        // then
        XCTAssert(person?.name == "Oliver")
    }
}

struct MyCodable: Codable {
    var id: Int
    var key: String
}

