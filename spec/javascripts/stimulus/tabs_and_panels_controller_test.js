/**
 * @jest-environment jsdom
 */

import { Application } from 'stimulus';
import tabs_and_panels_controller from '../../../app/webpacker/controllers/tabs_and_panels_controller';

describe('TabsAndPanelsController', () => {
  beforeAll(() => {
    const application = Application.start();
    application.register('tabs-and-panels', tabs_and_panels_controller);
  });

  describe('#tabs-and-panels', () => {
    const checkDefaultPanel = () => {
      const peekPanel = document.getElementById('peek_panel');
      const kaPanel = document.getElementById('ka_panel');
      const booPanel = document.getElementById('boo_panel');

      expect(peekPanel.style.display).toBe('block');
      expect(kaPanel.style.display).toBe('none');
      expect(booPanel.style.display).toBe('none');
    }

    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="tabs-and-panels" data-tabs-and-panels-class-name-value="selected">
          <a id="peek" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" class="selected" data-tabs-and-panels-target="tab">Peek</a>
          <a id="ka" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Ka</a>
          <a id="boo" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Boo</a>


          <div id="peek_panel" data-tabs-and-panels-target="panel default">Peek me</div>
          <div id="ka_panel" data-tabs-and-panels-target="panel">Ka you</div>
          <div id="boo_panel" data-tabs-and-panels-target="panel">Boo three</div>
        </div>`;
    });

    it('displays only the default panel', () => {
      checkDefaultPanel()
    });

    describe('when tab is clicked', () => {
      let ka;

      beforeEach(() => {
        ka = document.getElementById('ka');
      })

      it('displays appropriate panel', () => {
        const kaPanel = document.getElementById('ka_panel');

        expect(kaPanel.style.display).toBe('none');
        ka.click();
        expect(kaPanel.style.display).toBe('block');
      });

      it('selects the clicked tab', () => {
        ka.click();
        expect(ka.classList.contains('selected')).toBe(true);
      });

      describe("when panel doesn't exist", () => {
        beforeEach(() => {
          document.body.innerHTML = `
            <div data-controller="tabs-and-panels" data-tabs-and-panels-class-name-value="selected">
              <a id="peek" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" class="selected" data-tabs-and-panels-target="tab">Peek</a>
              <a id="ka" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Ka</a>
              <a id="boo" href="#" data-action="tabs-and-panels#changeActivePanel tabs-and-panels#changeActiveTab" data-tabs-and-panels-target="tab">Boo</a>


              <div id="peek_panel" data-tabs-and-panels-target="panel default">Peek me</div>
              <div id="boo_panel" data-tabs-and-panels-target="panel">Boo three</div>
            </div>`;
        });

        it('displays the current panel', () => {
          const peekPanel = document.getElementById('peek_panel');

          ka.click();
          expect(peekPanel.style.display).toBe('block');
        })
      })
    })

    describe('when anchor is specified in the url', () => {
      const { location } = window;
      const mockLocationToString = (panel) => {
        // Mocking window.location.toString() 
        const url = `http://localhost:3000/admin/enterprises/great-shop/edit#/${panel}`
        const mockedToString = jest.fn()
        mockedToString.mockImplementation(() => (url))

        delete window.location 
        window.location = {
          toString: mockedToString
        } 
      }

      beforeAll(() => {
        mockLocationToString('ka_panel')
      })

      afterAll(() => {
        // cleaning up
        window.location = location
      })

      it('displays the panel associated with the anchor', () => {
        const kaPanel = document.getElementById('ka_panel');

        expect(kaPanel.style.display).toBe('block');
      })

      it('selects the tab entry associated with the anchor', () => {
        const ka = document.getElementById('ka');

        expect(ka.classList.contains('selected')).toBe(true);
      })

      describe("when anchor doesn't macht any panel", () => {
        beforeAll(() => {
          mockLocationToString('random_panel')
        })

        it('displays the default panel', () => {
          checkDefaultPanel()
        })
      })
    })
  });
});
