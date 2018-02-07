require 'dry/schema/macros'

module Dry
  module Schema
    class DSL < BasicObject
      include ::Dry::Equalizer(:compiler, :options)

      attr_reader :compiler

      attr_reader :macros

      attr_reader :options

      def initialize(compiler, options = {}, &block)
        @macros = []
        @compiler = compiler
        @options = options
        instance_eval(&block) if block
      end

      def class
        ::Dry::Schema::DSL
      end

      def call
        macros.map { |m| [m.name, m.to_rule] }.to_h
      end

      def required(name, &block)
        macro = Macros::Required.new(name, compiler: compiler)
        macro.value(&block) if block
        macros << macro
        macro
      end

      def optional(name, &block)
        macro = Macros::Optional.new(name, compiler: compiler)
        macro.value(&block) if block
        macros << macro
        macro
      end
    end
  end
end
