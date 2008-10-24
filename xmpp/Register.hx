package xmpp;

import util.XmlUtil;


/**

	TODO check schema
	
*/
class Register {
	
	public static var XMLNS = "jabber:iq:register";
	
	public var username : String;
	public var password : String;
	public var email : String;
	public var name	: String;
	
	
	public function new( ?username:	String, ?password : String, ?email : String, ?name : String ) {
		this.username = username;
		this.password = password;
		this.email = email;
		this.name = name;
	}
	
	
	public function toXml() : Xml {
		var q = xmpp.IQ.createQuery( XMLNS );
		if( username != null ) q.addChild( XmlUtil.createElement( "username", username ) );
		if( password != null ) q.addChild( XmlUtil.createElement( "password", password ) );
		if( email != null ) q.addChild( XmlUtil.createElement( "email", email ) );
		if( name != null ) q.addChild( XmlUtil.createElement( "name", name ) );
		return q;
	}
	
	public inline function toString() : String {
		return toXml().toString();
	}
	
	
	public static function parse( x : Xml ) : xmpp.Register {
		var r = new xmpp.Register();
		//xmpp.Packet.reflectPacketNodes( x, r );
		for( e in x.elements() ) {
			var v : String = null;
			try { v = e.firstChild().nodeValue; } catch( e : Dynamic ) {}
			if( v != null ) {
				switch( e.nodeName ) {
					case "username" : r.username = v;
					case "password" : r.password = v;
					case "email"   : r.email = v;
					case "name" : r.name = v;
				}
			}
		}
		return r;
	}
	
}
