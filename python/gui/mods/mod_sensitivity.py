import logging
import os

from frameworks.wulf import WindowLayer
from gui.app_loader.settings import APP_NAME_SPACE
from gui.Scaleform.framework import g_entitiesFactories, ScopeTemplates, ViewSettings
from gui.Scaleform.framework.entities.View import View
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams
from gui.shared import g_eventBus, EVENT_BUS_SCOPE
from gui.shared.events import AppLifeCycleEvent
from gui.shared.personality import ServicesLocator

logger = logging.getLogger('Sensitivity Values')
logger.setLevel(logging.DEBUG if os.path.isfile('.debug_sensitivity') else logging.ERROR)

INJECTOR_LINKAGE = 'SensitivityInjector'
SWF_FILE = 'SensitivityInjector.swf'

_isInitialized = False
_isViewRegistered = False
_isEventListenerRegistered = False
_loadedInjectorNamespaces = set()
_activeViews = []


def _getTargetNamespaces():
    namespaces = [APP_NAME_SPACE.SF_LOBBY]
    battleNamespace = getattr(APP_NAME_SPACE, 'SF_BATTLE', None)
    if battleNamespace is not None:
        namespaces.append(battleNamespace)
    return namespaces


class SensitivityView(View):

    def _populate(self):
        super(SensitivityView, self)._populate()
        if self not in _activeViews:
            _activeViews.append(self)
        logger.debug('Sensitivity injector populated')

    def _dispose(self):
        global _loadedInjectorNamespaces
        if self in _activeViews:
            _activeViews.remove(self)
        if not _activeViews:
            _loadedInjectorNamespaces.clear()
        logger.debug('Sensitivity injector disposed')
        super(SensitivityView, self)._dispose()


def _loadInjector(namespace):
    global _loadedInjectorNamespaces
    if namespace in _loadedInjectorNamespaces:
        logger.debug('Sensitivity injector load skipped, already loaded for %s', namespace)
        return
    app = ServicesLocator.appLoader.getApp(namespace)
    if app is None and namespace != APP_NAME_SPACE.SF_LOBBY:
        app = ServicesLocator.appLoader.getDefBattleApp()
    if app is not None:
        try:
            app.loadView(SFViewLoadParams(INJECTOR_LINKAGE))
            _loadedInjectorNamespaces.add(namespace)
            logger.debug('Sensitivity injector load requested for %s', namespace)
        except Exception:
            _loadedInjectorNamespaces.discard(namespace)
            raise


def _loadInjectors():
    for namespace in _getTargetNamespaces():
        _loadInjector(namespace)


def _onAppInitialized(event):
    if event.ns not in _getTargetNamespaces():
        return
    try:
        _loadInjector(event.ns)
    except Exception:
        logger.exception('Sensitivity injector load failed for %s', event.ns)


def init():
    global _isInitialized
    global _isViewRegistered
    global _isEventListenerRegistered
    if _isInitialized:
        return
    try:
        if not _isViewRegistered:
            g_entitiesFactories.addSettings(ViewSettings(INJECTOR_LINKAGE, SensitivityView, SWF_FILE, WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE))
            _isViewRegistered = True
            logger.debug('Sensitivity view registered')
        if not _isEventListenerRegistered:
            g_eventBus.addListener(AppLifeCycleEvent.INITIALIZED, _onAppInitialized, scope=EVENT_BUS_SCOPE.GLOBAL)
            _isEventListenerRegistered = True
            logger.debug('Sensitivity lifecycle listener registered')
        try:
            _loadInjectors()
        except Exception:
            logger.exception('Sensitivity immediate injector load failed')
        _isInitialized = True
        logger.debug('Sensitivity loaded')
    except Exception:
        logger.exception('Failed to initialize Sensitivity')


def fini():
    global _isInitialized
    global _isEventListenerRegistered
    global _loadedInjectorNamespaces
    try:
        if _isEventListenerRegistered:
            g_eventBus.removeListener(AppLifeCycleEvent.INITIALIZED, _onAppInitialized, scope=EVENT_BUS_SCOPE.GLOBAL)
            _isEventListenerRegistered = False
            logger.debug('Sensitivity lifecycle listener removed')
        _activeViews[:] = []
        _loadedInjectorNamespaces.clear()
        _isInitialized = False
        logger.debug('Sensitivity unloaded')
    except Exception:
        logger.exception('Failed to finalize Sensitivity')
