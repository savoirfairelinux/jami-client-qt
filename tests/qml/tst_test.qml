import QtQuick 2.14
import QtTest 1.2

TestCase {
    name: "MathTests"

    function test_math() {
        compare(2 + 2, 4, "2 + 2 = 4")
    }
}
