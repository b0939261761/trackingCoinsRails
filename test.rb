p "First:231\nSecond: some_text\nThirth: 88".scan(/(?<=:).+(?=\s*$)/).map(&:strip)
