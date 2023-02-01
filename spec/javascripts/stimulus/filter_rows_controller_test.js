/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import filter_rows_controller from "../../../app/webpacker/controllers/filter_rows_controller";

describe("Filter rows", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("filter-rows", filter_rows_controller);
  });

  describe("test method", () => {
    beforeEach(() => {
      document.body.innerHTML = `<div data-controller="filter-rows">
          <input id="search" type="text" data-action="input->filter-rows#filter" />
         
          <table>
            <tr data-searchable="1" data-filter-rows-target="row">
              <td >1</td>
            </tr>
            <tr data-searchable="2" data-filter-rows-target="row">
              <td >2</td>
            </tr>
            <tr data-searchable="11" data-filter-rows-target="row">
              <td >11</td>
            </tr>
          </table>
       </div>`;
    });

    it("#filter()", () => {
      const search = document.getElementById("search");
      const row1 = document.querySelector("tr:nth-child(1)");
      const row2 = document.querySelector("tr:nth-child(2)");
      const row3 = document.querySelector("tr:nth-child(3)");

      // Display all rows since we haven't searched anything yet
      expect(row1.style.display).toBe("");
      expect(row2.style.display).toBe("");
      expect(row3.style.display).toBe("");

      // Display rows that contains '1' in their data-searchable attribute
      search.value = "1";
      search.dispatchEvent(new Event("input"));

      expect(row1.style.display).toBe("");
      expect(row2.style.display).toBe("none");
      expect(row3.style.display).toBe("");

      // Display rows that contains '2' in their data-searchable attribute
      search.value = "2";
      search.dispatchEvent(new Event("input"));

      expect(row1.style.display).toBe("none");
      expect(row2.style.display).toBe("");
      expect(row3.style.display).toBe("none");

      // Display all rows since the search input is empty
      search.value = "";
      search.dispatchEvent(new Event("input"));

      expect(row1.style.display).toBe("");
      expect(row2.style.display).toBe("");
      expect(row3.style.display).toBe("");
    });
  });
});
