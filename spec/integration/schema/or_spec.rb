# frozen_string_literal: true

RSpec.describe Dry::Schema, "OR messages" do
  context "with two predicates" do
    subject(:schema) do
      Dry::Schema.define do
        required(:foo) { str? | int? }
      end
    end

    it "returns success for valid input" do
      expect(schema.(foo: "bar")).to be_success
      expect(schema.(foo: 321)).to be_success
    end

    it "provides OR error message for invalid input where all both sides failed" do
      expect(schema.(foo: []).errors).to eql(foo: ["must be a string or must be an integer"])
    end
  end

  context "with a predicate and a conjunction of predicates" do
    subject(:schema) do
      Dry::Schema.define do
        required(:foo) { str? | (int? & gt?(18)) }
      end
    end

    it "returns success for valid input" do
      expect(schema.(foo: "bar")).to be_success
      expect(schema.(foo: 321)).to be_success
    end

    it "provides OR message for invalid input where both sides failed" do
      expect(schema.(foo: []).errors).to eql(foo: ["must be a string or must be an integer"])
    end

    it "provides error messages for invalid input where right side failed" do
      expect(schema.(foo: 17).errors).to eql(foo: ["must be a string or must be greater than 18"])
    end
  end

  context "with a predicate and an each operation" do
    subject(:schema) do
      Dry::Schema.define do
        required(:foo) { str? | value(:array?).each(:int?) }
      end
    end

    it "returns success for valid input" do
      expect(schema.(foo: "bar")).to be_success
      expect(schema.(foo: [1, 2, 3])).to be_success
    end

    it "provides OR message for invalid input where both sides failed" do
      expect(schema.(foo: {}).errors).to eql(foo: ["must be a string or must be an array"])
    end

    it "provides error messages for invalid input where right side failed" do
      expect(schema.(foo: %w[1 2 3]).errors).to eql(
        foo: {
          0 => ["must be an integer"],
          1 => ["must be an integer"],
          2 => ["must be an integer"]
        }
      )
    end
  end

  context "with a predicate and a schema" do
    subject(:schema) do
      Dry::Schema.define do
        required(:foo) { str? | hash { required(:bar).filled } }
      end
    end

    it "returns success for valid input" do
      expect(schema.(foo: "bar")).to be_success
      expect(schema.(foo: {bar: "baz"})).to be_success
    end

    it "provides OR message for invalid input where both sides failed" do
      expect(schema.(foo: []).errors).to eql(foo: ["must be a string or must be a hash"])
    end

    it "provides error messages for invalid input where right side rules failed" do
      expect(schema.(foo: {bar: ""}).errors).to eql(foo: {bar: ["must be filled"]})
    end
  end

  context "with two schemas" do
    name_schema = Dry::Schema.define do
      required(:name).filled(:str?)
    end

    first_name_schema = Dry::Schema.define do
      required(:first_name).filled(:str?)
    end

    subject(:schema) do
      Dry::Schema.define do
        required(:user).schema(name_schema | first_name_schema)
      end
    end

    it "returns success for valid input" do
      expect(schema.(user: { name: "John" })).to be_success
      expect(schema.(user: { first_name: "John" })).to be_success
    end

    it "returns OR error message for invalid input" do
      expect(schema.(user: { last_name: "John" }).errors.to_h).to eq(:user=>{:or=>[{:name=>["is missing"]},
                                                                                   {:first_name=>["is missing"]}]})
    end

    context "when one schema contains another nested schema" do
      scale_options_schema = Dry::Schema.define do
        required(:value)
        required(:text).filled(:string)
      end

      scale_schema = Dry::Schema.define do
        required(:type).filled(eql?: "scale")
        required(:id).filled(:string)
        required(:options)
            .value(:array, min_size?: 1)
            .each(:hash, scale_options_schema)
      end

      questions_schema = Dry::Schema.define do
        required(:type).filled(eql?: "question")
        required(:id).filled(:string)
        required(:text).filled(:string)
      end

      subject(:schema) do
        Dry::Schema.define do
          required(:definitions)
              .value(:array, min_size?: 1)
              .each(:hash, questions_schema | scale_schema)
        end
      end

      it "returns success for valid input" do
        valid_hash = {
            definitions: [
                {
                    type: "scale",
                    id: "1",
                    options: [
                        {
                            text: "No",
                            value: 1,
                        },
                        {
                            text: "Yes",
                            value: 2,
                        },
                    ],
                },
                {
                    id: "2",
                    type: "question",
                    text: "hello",
                },
            ],
        }

        expect(schema.(valid_hash)).to be_success
      end
    end
  end
end
