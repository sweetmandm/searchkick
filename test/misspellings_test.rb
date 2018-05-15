require_relative "test_helper"

class MisspellingsTest < Minitest::Test
  def test_misspellings
    store_names ["abc", "abd", "aee"]
    assert_search "abc", ["abc"], misspellings: false
  end

  def test_misspellings_distance
    store_names ["abbb", "aabb"]
    assert_search "aaaa", ["aabb"], misspellings: {distance: 2}
  end

  def test_misspellings_prefix_length
    store_names ["ap", "api", "apt", "any", "nap", "ah", "ahi"]
    assert_search "ap", ["ap"], misspellings: {prefix_length: 2}
    assert_search "api", ["ap", "api", "apt"], misspellings: {prefix_length: 2}
  end

  def test_misspellings_prefix_length_operator
    store_names ["ap", "api", "apt", "any", "nap", "ah", "aha"]
    assert_search "ap ah", ["ap", "ah"], operator: "or", misspellings: {prefix_length: 2}
    assert_search "api ahi", ["ap", "api", "apt", "ah", "aha"], operator: "or", misspellings: {prefix_length: 2}
  end

  def test_misspellings_fields_operator
    store [
      {name: "red", color: "red"},
      {name: "blue", color: "blue"},
      {name: "cyan", color: "blue green"},
      {name: "magenta", color: "red blue"},
      {name: "green", color: "green"}
    ]
    assert_search "red blue", ["red", "blue", "cyan", "magenta"], operator: "or", fields: ["color"], misspellings: false
  end

  def test_misspellings_below_unmet
    store_names ["abc", "abd", "aee"]
    assert_search "abc", ["abc", "abd"], misspellings: {below: 2}
  end

  def test_misspellings_below_unmet_result
    store_names ["abc", "abd", "aee"]
    assert Product.search("abc", misspellings: {below: 2}).misspellings?
  end

  def test_misspellings_below_met
    store_names ["abc", "abd", "aee"]
    assert_search "abc", ["abc"], misspellings: {below: 1}
  end

  def test_misspellings_below_met_result
    store_names ["abc", "abd", "aee"]
    assert !Product.search("abc", misspellings: {below: 1}).misspellings?
  end

  def test_misspellings_field_correct_spelling_still_works
    store [{name: "Sriracha", color: "blue"}]
    assert_misspellings "Sriracha", ["Sriracha"], {fields: {name: false, color: false}}
    assert_misspellings "blue", ["Sriracha"], {fields: {name: false, color: false}}
  end

  def test_misspellings_field_enabled
    store [{name: "Sriracha", color: "blue"}]
    assert_misspellings "siracha", ["Sriracha"], {fields: {name: true}}
    assert_misspellings "clue", ["Sriracha"], {fields: {color: true}}
  end

  def test_misspellings_field_disabled
    store [{name: "Sriracha", color: "blue"}]
    assert_misspellings "siracha", [], {fields: {name: false}}
    assert_misspellings "clue", [], {fields: {color: false}}
  end

  def test_misspellings_field__color
    store [{name: "Sriracha", color: "blue"}]
    assert_misspellings "bluu", ["Sriracha"], {fields: {name: false, color: true}}
  end

  def test_misspellings_field_multiple
    store [
      {name: "Greek Yogurt", color: "white"},
      {name: "Green Onions", color: "yellow"}
    ]
    assert_misspellings "greed", ["Greek Yogurt", "Green Onions"], {fields: {name: true, color: false}}
    assert_misspellings "greed", [], {fields: {name: false, color: true}}
  end

  def test_misspellings_field_unspecified_uses_edit_distance_one
    store [{name: "Bingo", color: "blue"}]
    assert_misspellings "bin", [], {fields: {color: {edit_distance: 2}}}
    assert_misspellings "bingooo", [], {fields: {color: {edit_distance: 2}}}
    assert_misspellings "mango", [], {fields: {color: {edit_distance: 2}}}
    assert_misspellings "bing", ["Bingo"], {fields: {color: {edit_distance: 2}}}
  end

  def test_misspellings_field_uses_specified_edit_distance
    store [{name: "Bingo", color: "yellow"}]
    assert_misspellings "yell", ["Bingo"], {fields: {color: {edit_distance: 2}}}
    assert_misspellings "yellowww", ["Bingo"], {fields: {color: {edit_distance: 2}}}
    assert_misspellings "yilliw", ["Bingo"], {fields: {color: {edit_distance: 2}}}
  end

  def test_misspellings_field_zucchini_transposition
    store [{name: "zucchini", color: "green"}]
    assert_misspellings "zuccihni", [], {fields: {name: {transpositions: false}}}
    assert_misspellings "grene", ["zucchini"], {fields: {name: {transpositions: false}}}
  end

  def test_misspellings_field_transposition_combination
    store [{name: "zucchini", color: "green"}]
    misspellings = {
        transpositions: false,
        fields: {color: {transpositions: true}}
    }
    assert_misspellings "zuccihni", [], misspellings
    assert_misspellings "greene", ["zucchini"], misspellings
  end

  def test_misspellings_field_word_start
    store_names ["Sriracha"]
    assert_misspellings "siracha", ["Sriracha"], {fields: {name: true}}
  end

  def test_misspellings_field_and_transpositions
    store [{name: "Sriracha", color: "green"}]
    options = {
      fields: [{name: :word_start}],
      misspellings: {
        transpositions: false,
        fields: {name: true}
      }
    }
    assert_search "grene", [], options
    assert_search "srircaha", ["Sriracha"], options
  end

  def test_misspellings_field_and_edit_distance
    store [{name: "Sriracha", color: "green"}]
    options = {edit_distance: 2, fields: {name: true}}
    assert_misspellings "greennn", ["Sriracha"], options
    assert_misspellings "srirachaaa", [], options
    assert_misspellings "siracha", ["Sriracha"], options
  end

  def test_misspellings_field_requires_explicit_search_fields
    store_names ["Sriracha"]
    assert_raises(ArgumentError) do
      assert_search "siracha", ["Sriracha"], {misspellings: {fields: {name: false}}}
    end
  end
end
