# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::DisabledButtonComponent, type: :component do
  it "renders attributes via tag helpers so class is not HTML-escaped" do
    render_inline(described_class.new(
      text: "S'inscrire",
      disabled: true,
      disabled_reason: "Indisponible",
      classes: "btn-primary text-sm"
    ))

    expect(rendered_content).not_to include('class="&quot;')
    doc = Nokogiri::HTML::DocumentFragment.parse(rendered_content)
    btn = doc.at_css("button")
    expect(btn["type"]).to eq("button")
    expect(btn["class"]).to include("btn-primary", "inline-flex")
    expect(btn["disabled"]).to be_present
    expect(btn["title"]).to eq("Indisponible")
  end

  it "renders hint span wired with aria-describedby when hint is present" do
    render_inline(described_class.new(
      text: "Sign up",
      disabled: true,
      disabled_reason: "Closed",
      hint: "Soon"
    ))

    doc = Nokogiri::HTML::DocumentFragment.parse(rendered_content)
    button = doc.at_css("button")
    hint = doc.at_css("span")
    expect(button["aria-describedby"]).to eq(hint["id"])
    expect(hint.text.strip).to eq("Soon")
    expect(doc.at_css("div")).to be_present
  end

  it "renders disabled reason in a below-the-button note visible only below md when enabled" do
    render_inline(described_class.new(
      text: "S'inscrire",
      disabled: true,
      disabled_reason: "Création de compte en ligne indisponible pour le moment.",
      show_disabled_reason_below_md: true,
      classes: "btn-primary"
    ))

    doc = Nokogiri::HTML::DocumentFragment.parse(rendered_content)
    button = doc.at_css("button")
    note = doc.at_css("p")
    expect(note["class"]).to include("md:hidden")
    expect(note.text).to include("indisponible")
    expect(button["aria-describedby"]).to eq(note["id"])
  end
end
