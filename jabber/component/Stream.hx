package jabber.component;

import jabber.ServiceDiscoveryListener;


/**
	Base for Component-2-Server jabber streams.<br/>
	<a href="http://www.xmpp.org/extensions/xep-0114.html">XEP-0114: Jabber Component Protocol</a>
*/
class Stream extends jabber.Stream {
	
	public static inline var STANDARD_PORT = 5275;
	public static var defaultPort = STANDARD_PORT;
	
	/** Dispatched on authentication success */
	public dynamic function onConnect( success : Bool ) : Void;
	
	/** */
	public var host(default,null) : String;
	/** This components subdomain */
	public var subdomain(default,null) : String;
	/** Shared secret used to identify legacy components*/
	public var secret(default,null) : String;
	/**  */
	public var authenticated(default,null) : Bool;
	/** */
	public var serviceListener(default,null) : ServiceDiscoveryListener;
	
	
	/**
	*/
	public function new( host : String, subdomain : String, secret : String, cnx : jabber.StreamConnection,
						 ?identity : xmpp.disco.Identity ) {
						 	
		if( subdomain == null || subdomain == "" ) throw "Invalid subdomain";
		if( secret == null ) throw "Invalid secret (null)";

		super( cnx, null );
		this.host = host;
		this.subdomain = subdomain;
		this.secret = secret;
		
		authenticated = false;
		serviceListener = new ServiceDiscoveryListener( this, identity );
	}
	
	
	override function connectHandler() {
		sendData( xmpp.Stream.createOpenStream( xmpp.Stream.XMLNS_COMPONENT, subdomain ) );
		status = jabber.StreamStatus.pending;
		cnx.read( true );
	}

	override function dataHandler( data : String ) {
		super.dataHandler( data );
		switch( status ) {
		case pending : return;
		case closed : return;
		case open : collectXml( Xml.parse( data ) );
		}
	}
	
	override function processStreamInit( s : String ) {
		var d = util.XmlUtil.removeXmlHeader( s );
		var dx = Xml.parse( d+"</stream:stream>" ).firstChild();
		id = dx.get( "id" );
		status = jabber.StreamStatus.open;
		onOpen();
		collectors.add( new  jabber.core.PacketCollector( [ cast new xmpp.filter.PacketNameFilter( ~/handshake/ ) ], readyHandler, false ) );
		var handshake = Xml.createElement( "handshake" );
		handshake.addChild( Xml.createPCData( crypt.SHA1.encode( id+secret ) ) );
		sendData( handshake.toString() );
	}
	
	function readyHandler( p : xmpp.Packet ) {
		authenticated = true;
		onConnect( true );
	}
	
}
