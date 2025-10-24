/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import { screen } from "@testing-library/dom";

import tag_list_input_controller from "tag_list_input_component/tag_list_input_controller";

// Mock jest to return an autocomplete list
global.fetch = jest.fn(() => {
  const html = `
    <li 
      data-testid="item" 
      class="suggestion-item"
      data-autocomplete-label="tag-1"
      data-autocomplete-value="tag-1"
      role="option"
      id="stimulus-autocomplete-option-4"
    >
      tag-1 has 1 rule
    </li>
    <li 
      data-testid="item"
      class="suggestion-item"
      data-autocomplete-label="rule-2"
      data-autocomplete-value="rule-2"
      role="option"
      id="stimulus-autocomplete-option-5"
    >
      rule-2 has 2 rules
    </li>`;

  return Promise.resolve({
    ok: true,
    text: () => Promise.resolve(html),
  });
});

describe("TagListInputController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("tag-list-input", tag_list_input_controller);
    jest.useFakeTimers();
  });

  beforeEach(() => {
    // Tag input with three existing tags
    document.body.innerHTML = `
      <div 
        data-controller="tag-list-input"
        data-action="autocomplete.change->tag-list-input#addTag"
        data-tag-list-input-url-value="/admin/tag_rules/variant_tag_rules?enterprise_id=3" 
       >
        <input 
          value="tag-1,tag-2,tag-3" 
          data-tag-list-input-target="tagList" 
          type="hidden" 
          name="variant_tag_list" 
          id="variant_tag_list"
        >
        <div class="tags-input">
          <div class="tags">
            <ul class="tag-list" data-tag-list-input-target="list">
              <template data-tag-list-input-target="template">
                <li class="tag-item">
                  <div class="tag-template">
                  <span></span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input#removeTag"
                  >✖</a>
                  </div>
                </li>
              </template>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag-1</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag-2</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag-3</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
            </ul>
            <input 
              type="text" 
              name="variant_add_tag" 
              id="variant_add_tag" 
              placeholder="Add a tag" 
              data-action="keydown.enter->tag-list-input#keyboardAddTag keyup->tag-list-input#filterInput focus->tag-list-input#onInputChange blur->tag-list-input#onBlur"
              data-tag-list-input-target="input"
              style="display: block;"
            >
          </div>
          <ul data-testid="suggestion-list" class="suggestion-list" data-tag-list-input-target="results" hidden></ul>
        </div>
      </div>`;
  });

  describe("addTag", () => {
    beforeEach(() => {
      variant_add_tag.value = "new_tag";
      variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    });

    it("updates the hidden input tag list", () => {
      expect(variant_tag_list.value).toBe("tag-1,tag-2,tag-3,new_tag");
    });

    it("adds the new tag to the HTML tag list", () => {
      const tagList = document.getElementsByClassName("tag-list")[0];

      // 1 template + 3 tags + 1 new tag
      expect(tagList.childElementCount).toBe(5);
    });

    it("clears the tag input", () => {
      expect(variant_add_tag.value).toBe("");
    });

    describe("with a tag with spaces", () => {
      it("replaces spaces by -", () => {
        variant_add_tag.value = "tag other";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));

        const tagList = document.getElementsByClassName("tag-list")[0];

        // 1 template + 3 tags + new tag (added in the beforeEach) + tag other
        expect(tagList.childElementCount).toBe(6);
        // Get the last span which is the last added tag
        const spans = document.getElementsByTagName("span");
        const span = spans.item(spans.length - 1);
        expect(span.innerText).toBe("tag-other");
      });
    });

    describe("with an empty new tag", () => {
      it("doesn't add the tag", () => {
        variant_add_tag.value = " ";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));

        const tagList = document.getElementsByClassName("tag-list")[0];

        // 1 template + 3 tags + new tag (added in the beforeEach)
        expect(tagList.childElementCount).toBe(5);
      });
    });

    describe("when tag already exist", () => {
      beforeEach(() => {
        // Trying to add an existing tag
        variant_add_tag.value = "tag 2";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
      });

      it("doesn't add the tag", () => {
        const tagList = document.getElementsByClassName("tag-list")[0];

        // 1 template + 4 tags
        expect(tagList.childElementCount).toBe(5);
        expect(variant_add_tag.value).toBe("tag 2");
      });

      it("highlights the new tag name in red", () => {
        expect(variant_add_tag.classList).toContain("tag-error");
      });
    });

    describe("when no tag yet", () => {
      it("doesn't include leading comma in hidden tag list input", () => {
        variant_tag_list.value = "";

        variant_add_tag.value = "latest";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));

        expect(variant_tag_list.value).toBe("latest");
      });
    });

    describe("when only one tag allowed", () => {
      beforeEach(() => {
        // Tag input with non existing tag
        document.body.innerHTML = `
          <div 
            data-controller="tag-list-input" 
            data-action="autocomplete.change->tag-list-input#addTag"
            data-tag-list-input-url-value="/admin/tag_rules/variant_tag_rules?enterprise_id=3"
            data-tag-list-input-only-one-value="true"
          >
            <input 
              value="" 
              data-tag-list-input-target="tagList" 
              type="hidden" 
              name="variant_tag_list" id="variant_tag_list"
            >
            <div class="tags-input">
              <div class="tags">
                <ul class="tag-list" data-tag-list-input-target="list">
                  <template data-tag-list-input-target="template">
                    <li class="tag-item">
                      <div class="tag-template">
                      <span></span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                      </div>
                    </li>
                  </template>
                </ul>
                <input 
                  type="text" 
                  name="variant_add_tag" 
                  id="variant_add_tag" 
                  placeholder="Add a tag" 
                  data-action="keydown.enter->tag-list-input#keyboardAddTag keyup->tag-list-input#filterInput blur->tag-list-input#onBlur focus->tag-list-input#onInputChange"
                  data-tag-list-input-target="input"
                  style="display: block;"
                >
              </div>
              <ul class="suggestion-list" data-tag-list-input-target="results" hidden></ul>
            </div>
          </div>`;
      });

      it("hides the tag input ", () => {
        variant_add_tag.value = "new_tag";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
        expect(variant_add_tag.style.display).toBe("none");
      });
    });
  });

  describe("removeTag", () => {
    beforeEach(() => {
      const removeButtons = document.getElementsByClassName("remove-button");
      // Click on tag-2
      removeButtons[1].click();
    });

    it("updates the hidden input tag list", () => {
      expect(variant_tag_list.value).toBe("tag-1,tag-3");
    });

    it("removes the tag from the HTML tag list", () => {
      const tagList = document.getElementsByClassName("tag-list")[0];
      // 1 template + 2 tags
      expect(tagList.childElementCount).toBe(3);
    });

    describe("when only one tag allowed", () => {
      beforeEach(() => {
        // Tag input with one existing tag
        document.body.innerHTML = `
          <div 
            data-controller="tag-list-input" 
            data-action="autocomplete.change->tag-list-input#addTag"
            data-tag-list-input-url-value="/admin/tag_rules/variant_tag_rules?enterprise_id=3"
            data-tag-list-input-only-one-value="true"
          >
            <input 
              value="" 
              data-tag-list-input-target="tagList" 
              type="hidden" 
              name="variant_tag_list" id="variant_tag_list"
            >
            <div class="tags-input">
              <div class="tags">
                <ul class="tag-list" data-tag-list-input-target="list">
                  <template data-tag-list-input-target="template">
                    <li class="tag-item">
                      <div class="tag-template">
                      <span></span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                      </div>
                    </li>
                  </template>
                  <li class="tag-item">
                    <div class="tag-template">
                      <span>tag-1</span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                    </div>
                  </li>
                </ul>
                <input 
                  type="text" 
                  name="variant_add_tag" 
                  id="variant_add_tag" 
                  placeholder="Add a tag" 
                  data-action="keydown.enter->tag-list-input#keyboardAddTag keyup->tag-list-input#filterInput blur->tag-list-input#onBlur focus->tag-list-input#onInputChange"
                  data-tag-list-input-target="input"
                  style="display: block;"
                >
              </div>
              <ul class="suggestion-list" data-tag-list-input-target="results" hidden></ul>
            </div>
          </div>`;
      });

      it("shows the tag input", () => {
        const removeButtons = document.getElementsByClassName("remove-button");
        removeButtons[0].click();

        expect(variant_add_tag.style.display).toBe("block");
      });
    });
  });

  describe("filterInput", () => {
    it("removes comma from the tag input", () => {
      variant_add_tag.value = "text";
      variant_add_tag.dispatchEvent(new KeyboardEvent("keyup", { key: "," }));

      expect(variant_add_tag.value).toBe("text");
    });

    it("removes error highlight", () => {
      variant_add_tag.value = "text";
      variant_add_tag.classList.add("tag-error");

      variant_add_tag.dispatchEvent(new KeyboardEvent("keyup", { key: "a" }));

      expect(variant_add_tag.classList).not.toContain("tag-error");
    });
  });

  describe("onBlur", () => {
    it("adds the tag", () => {
      variant_add_tag.value = "newer_tag";
      variant_add_tag.dispatchEvent(new FocusEvent("blur"));

      expect(variant_tag_list.value).toBe("tag-1,tag-2,tag-3,newer_tag");
    });

    describe("with autocomplete results", () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <div 
            data-controller="tag-list-input"
            data-action="autocomplete.change->tag-list-input#addTag"
            data-tag-list-input-url-value="/admin/tag_rules/variant_tag_rules?enterprise_id=3" 
           >
            <input 
              value="tag-1,tag-2,tag-3" 
              data-tag-list-input-target="tagList" 
              type="hidden" 
              name="variant_tag_list" 
              id="variant_tag_list"
            >
            <div class="tags-input">
              <div class="tags">
                <ul class="tag-list" data-tag-list-input-target="list">
                  <template data-tag-list-input-target="template">
                    <li class="tag-item">
                      <div class="tag-template">
                      <span></span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                      </div>
                    </li>
                  </template>
                  <li class="tag-item">
                    <div class="tag-template">
                      <span>tag-1</span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                    </div>
                  </li>
                  <li class="tag-item">
                    <div class="tag-template">
                      <span>tag-2</span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                    </div>
                  </li>
                  <li class="tag-item">
                    <div class="tag-template">
                      <span>tag-3</span>
                      <a 
                        class="remove-button" 
                        data-action="click->tag-list-input#removeTag"
                      >✖</a>
                    </div>
                  </li>
                </ul>
                <input 
                  type="text" 
                  name="variant_add_tag" 
                  id="variant_add_tag" 
                  placeholder="Add a tag" 
                  data-action="keydown.enter->tag-list-input#keyboardAddTag keyup->tag-list-input#filterInput blur->tag-list-input#onBlur focus->tag-list-input#onInputChange"
                  data-tag-list-input-target="input"
                  style="display: block;"
                >
              </div>
              <ul class="suggestion-list" data-tag-list-input-target="results">
                <li 
                  class="suggestion-item" 
                  data-autocomplete-label="rule-1" 
                  data-autocomplete-value="rule-1" 
                  role="option" 
                  id="stimulus-autocomplete-option-4"
                >
                  rule-1 has 1 rule
                </li>
                <li 
                  class="suggestion-item" 
                  data-autocomplete-label="rule-2" 
                  data-autocomplete-value="rule-2" 
                  role="option" 
                  id="stimulus-autocomplete-option-5"
                 >
                  rule-2 has 2 rules
                </li>
              </ul>
            </div>
          </div>`;
      });

      it("doesn't add the tag", () => {
        variant_add_tag.value = "newer_tag";
        variant_add_tag.dispatchEvent(new FocusEvent("blur"));

        expect(variant_tag_list.value).toBe("tag-1,tag-2,tag-3");
      });
    });
  });

  describe("replaceResults", () => {
    beforeEach(() => {
      fetch.mockClear();
    });

    it("filters out existing tags in the autocomplete dropdown", async () => {
      variant_add_tag.dispatchEvent(new FocusEvent("focus"));
      // onInputChange uses a debounce function implemented using setTimeout
      jest.runAllTimers();

      // findAll* will wait for all promises to be finished before returning a result, this ensure
      // the dom has been updated with the autocomplete data
      const items = await screen.findAllByTestId("item");
      expect(items.length).toBe(1);
      expect(items[0].textContent.trim()).toBe("rule-2 has 2 rules");
    });
  });
});
